"""
Phase 1: PDF Ingestion & Embedding Pipeline
===========================================
Usage:
    cd backend
    python -m app.ingest

This script will:
  1. Discover all PDF files under data/documents/
  2. Load and parse each PDF page-by-page (preserving metadata)
  3. Split text into overlapping chunks using RecursiveCharacterTextSplitter
  4. Embed chunks using the configured HuggingFace model (BGE-m3 or E5)
  5. Persist the resulting ChromaDB vector store to disk
"""

import logging
from pathlib import Path
from tqdm import tqdm

from langchain_community.document_loaders import PyPDFLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma

from app.config import settings

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Step 1: Discover PDF files
# ---------------------------------------------------------------------------
def discover_pdfs(documents_dir: Path) -> list[Path]:
    """Return a sorted list of all PDF paths under documents_dir."""
    pdfs = sorted(documents_dir.rglob("*.pdf"))
    if not pdfs:
        raise FileNotFoundError(
            f"No PDF files found in '{documents_dir}'. "
            "Please add your university regulation/syllabus PDFs and re-run."
        )
    log.info(f"Discovered {len(pdfs)} PDF file(s):")
    for p in pdfs:
        log.info(f"  • {p.relative_to(documents_dir.parent)}")
    return pdfs


# ---------------------------------------------------------------------------
# Step 2: Load & parse PDFs — preserving page-level source metadata
# ---------------------------------------------------------------------------
def load_documents(pdf_paths: list[Path]):
    """
    Load every page from every PDF.
    Each returned Document carries metadata:
        { "source": "filename.pdf", "page": N }
    which will be surfaced in the Flutter UI as the citation.
    """
    all_docs = []
    for pdf_path in tqdm(pdf_paths, desc="Loading PDFs"):
        loader = PyPDFLoader(str(pdf_path))
        pages = loader.load()

        # Normalise the source field to just the filename (not the full OS path)
        for page in pages:
            page.metadata["source"] = pdf_path.name
            # PyPDFLoader already sets page.metadata["page"] (0-indexed).
            # We convert to 1-indexed for human-readable citations.
            page.metadata["page"] = page.metadata.get("page", 0) + 1

        all_docs.extend(pages)
        log.info(f"  Loaded '{pdf_path.name}' → {len(pages)} page(s)")

    log.info(f"Total pages loaded: {len(all_docs)}")
    return all_docs


# ---------------------------------------------------------------------------
# Step 3: Chunk documents
# ---------------------------------------------------------------------------
def chunk_documents(documents):
    """
    Split page-level documents into smaller, semantically coherent chunks.

    RecursiveCharacterTextSplitter tries to split on paragraph → sentence →
    word boundaries in that order, so chunks rarely cut mid-thought.

    Settings (from config):
        chunk_size    = 500 chars  (~100-120 words in Turkish)
        chunk_overlap = 50  chars  (ensures no sentence is orphaned at a boundary)
    """
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=settings.CHUNK_SIZE,
        chunk_overlap=settings.CHUNK_OVERLAP,
        separators=["\n\n", "\n", ".", " ", ""],   # Turkish-friendly hierarchy
        length_function=len,
    )
    chunks = splitter.split_documents(documents)
    log.info(
        f"Chunking complete: {len(documents)} pages → {len(chunks)} chunks "
        f"(size={settings.CHUNK_SIZE}, overlap={settings.CHUNK_OVERLAP})"
    )
    return chunks


# ---------------------------------------------------------------------------
# Step 4: Build embeddings + persist ChromaDB
# ---------------------------------------------------------------------------
def build_vectorstore(chunks):
    """
    Embed all chunks and persist them to disk as a ChromaDB collection.

    BGE-m3 is preferred: it handles Turkish text well and supports
    long-context embeddings (up to 8192 tokens).

    On first run this downloads ~1–2 GB of model weights.
    Subsequent runs load from the HuggingFace cache instantly.
    """
    log.info(f"Loading embedding model: '{settings.EMBEDDING_MODEL}' …")
    log.info("(First run will download model weights — this may take a few minutes.)")

    embeddings = HuggingFaceEmbeddings(
        model_name=settings.EMBEDDING_MODEL,
        model_kwargs={"device": "cpu"},   # Switch to "cuda" if you have a GPU
        encode_kwargs={"normalize_embeddings": True},  # Required for cosine similarity
    )

    log.info(f"Embedding {len(chunks)} chunks and saving to ChromaDB …")

    # Chroma.from_documents() embeds + persists in one call.
    vectorstore = Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        collection_name=settings.CHROMA_COLLECTION_NAME,
        persist_directory=str(settings.VECTORSTORE_DIR),
    )

    log.info(
        f"✅ Vector store saved to '{settings.VECTORSTORE_DIR}' "
        f"({len(chunks)} vectors in collection '{settings.CHROMA_COLLECTION_NAME}')"
    )
    return vectorstore


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
def main():
    log.info("=" * 55)
    log.info("  Cep-Kampüs — Phase 1: Ingestion Pipeline")
    log.info("=" * 55)

    # Ensure output directory exists
    settings.VECTORSTORE_DIR.mkdir(parents=True, exist_ok=True)

    pdf_paths = discover_pdfs(settings.DOCUMENTS_DIR)
    documents = load_documents(pdf_paths)
    chunks = chunk_documents(documents)
    build_vectorstore(chunks)

    log.info("Phase 1 complete. Ready for Phase 2 (RAG API).")


if __name__ == "__main__":
    main()