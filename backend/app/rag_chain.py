"""
rag_chain.py — LangChain RAG pipeline (singleton, loaded once at startup).

Architecture:
    ChromaDB Retriever → Prompt Template → Groq LLM → Output Parser
"""

import logging
from functools import lru_cache

from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_groq import ChatGroq
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate

from app.config import settings

log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Anti-Hallucination System Prompt
# ---------------------------------------------------------------------------
# This is the most sensitive part of the entire system.
# The prompt is designed with three layers of guardrails:
#   1. A strict role definition that anchors the LLM's identity.
#   2. An explicit instruction to use ONLY the provided context.
#   3. A mandatory, verbatim fallback phrase for out-of-scope questions.
# Using triple-braced variables ensures LangChain passes context and question
# correctly without any formatting collisions.
# ---------------------------------------------------------------------------

STRICT_RAG_PROMPT = PromptTemplate(
    input_variables=["context", "question"],
    template="""Sen Cep-Kampüs'ün yapay zeka asistanısın. Görevin, Iğdır Üniversitesi öğrencilerinin yönetmelikler, ders programları ve duyurular hakkındaki sorularını yanıtlamaktır.

KURALLAR (Bu kurallara kesinlikle uy):
1. Yanıtını YALNIZCA aşağıda verilen "Bağlam" bölümündeki bilgilere dayandır.
2. Bağlamda bulunmayan hiçbir bilgiyi uydurmak, tahmin etmek veya genel bilginden tamamlamak kesinlikle yasaktır.
3. Eğer sorunun cevabı bağlamda yoksa, aşağıdaki şablonu AYNEN kullan ve başka hiçbir şey ekleme:

---
Üzgünüm, aradığınız bilgiye yönetmelik belgelerinde ulaşamadım.

Doğru ve güncel bilgi için lütfen Iğdır Üniversitesi ile doğrudan iletişime geçin:

📍 Adres: Şehit Bülent Yurtseven Kampüsü, 76000 Iğdır / Türkiye
📞 Çağrı Merkezi: 444 9 447
📧 Öğrenci E-posta: ogrenci@igdir.edu.tr
📧 Genel E-posta: info@igdir.edu.tr
---

4. Yanıtını net, anlaşılır ve akademik bir dille yaz.
5. Birden fazla ilgili madde varsa, hepsini sıralı şekilde belirt.

---
BAĞLAM:
{context}
---

ÖĞRENCİ SORUSU: {question}

YANIT:""",
)


# ---------------------------------------------------------------------------
# Embedding Loader (shared with ingest.py — same model, same config)
# ---------------------------------------------------------------------------

def _load_embeddings() -> HuggingFaceEmbeddings:
    log.info(f"Loading embedding model: '{settings.EMBEDDING_MODEL}' …")
    return HuggingFaceEmbeddings(
        model_name=settings.EMBEDDING_MODEL,
        model_kwargs={"device": "cpu"},
        encode_kwargs={"normalize_embeddings": True},
    )


# ---------------------------------------------------------------------------
# RAG Chain Factory (cached as a singleton)
# ---------------------------------------------------------------------------

@lru_cache(maxsize=1)
def get_rag_chain() -> RetrievalQA:
    """
    Build and return the RAG chain. Cached after first call.

    The @lru_cache decorator ensures the expensive operations —
    loading the embedding model and connecting to ChromaDB — happen
    exactly once when the FastAPI server starts, not on every request.
    """
    embeddings = _load_embeddings()

    log.info(f"Connecting to ChromaDB at '{settings.VECTORSTORE_DIR}' …")
    vectorstore = Chroma(
        collection_name=settings.CHROMA_COLLECTION_NAME,
        embedding_function=embeddings,
        persist_directory=str(settings.VECTORSTORE_DIR),
    )

    # MMR (Maximal Marginal Relevance) retrieval is used instead of simple
    # similarity search. MMR balances relevance with diversity, ensuring that
    # when multiple chunks from the same paragraph are retrieved, the model
    # receives broader context rather than redundant near-duplicate text.
    retriever = vectorstore.as_retriever(
        search_type="mmr",
        search_kwargs={
            "k": settings.TOP_K_RETRIEVAL,          # Final chunks returned
            "fetch_k": settings.TOP_K_RETRIEVAL * 3, # Candidate pool for MMR
            "lambda_mult": 0.7,  # 0=max diversity, 1=max relevance; 0.7 is balanced
        },
    )

    llm = ChatGroq(
        api_key=settings.GROQ_API_KEY,
        model=settings.LLM_MODEL,
        temperature=0.0,      # Zero temperature is mandatory for a factual RAG system.
                              # Any value above 0 introduces creative variance,
                              # which in this context manifests as hallucination.
        max_tokens=1024,
    )

    chain = RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",   # "stuff" = concatenate all retrieved chunks into one prompt.
                              # Optimal for TOP_K=4 with a 8192-token context window.
        retriever=retriever,
        return_source_documents=True,  # Critical: enables citation extraction.
        chain_type_kwargs={"prompt": STRICT_RAG_PROMPT},
    )

    log.info("✅ RAG chain is ready.")
    return chain