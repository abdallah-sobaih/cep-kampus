"""
main.py — FastAPI application entrypoint.

Endpoints:
    GET  /health  — Liveness probe (confirms server + chain are ready)
    POST /ask     — Core RAG endpoint consumed by the Flutter client
"""

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.schemas import AskRequest, AskResponse, SourceDocument
from app.rag_chain import get_rag_chain

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Lifespan: warm up the RAG chain before the server accepts traffic
# ---------------------------------------------------------------------------
# Using FastAPI's lifespan context manager (the modern replacement for
# @app.on_event("startup")) ensures the embedding model and ChromaDB
# connection are fully initialised before the first request arrives.
# A cold first request can otherwise take 10–30 seconds.
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    log.info("Server starting — warming up RAG chain …")
    get_rag_chain()   # Triggers @lru_cache; subsequent calls are instant.
    log.info("Warm-up complete. Server is ready to accept requests.")
    yield
    log.info("Server shutting down.")


# ---------------------------------------------------------------------------
# FastAPI App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Cep-Kampüs API",
    description="RAG-based university assistant backend. Powers the Cep-Kampüs Flutter app.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/health", tags=["Infrastructure"])
async def health_check():
    """Liveness probe. Returns 200 if the server and RAG chain are operational."""
    return {"status": "ok", "model": settings.LLM_MODEL}


@app.post("/ask", response_model=AskResponse, tags=["RAG"])
async def ask(request: AskRequest) -> AskResponse:
    """
    Core RAG endpoint.

    Accepts a student question, retrieves the most relevant document chunks
    from ChromaDB, grounds the LLM's answer in those chunks, and returns
    the answer alongside structured source citations.
    """
    log.info(f"Received query: '{request.query}'")
    t0 = time.perf_counter()

    try:
        chain = get_rag_chain()
        result = await _invoke_chain(chain, request.query)
    except Exception as exc:
        log.exception("RAG chain invocation failed.")
        raise HTTPException(status_code=500, detail=f"RAG pipeline error: {str(exc)}")

    answer: str = result["result"].strip()
    raw_sources: list = result.get("source_documents", [])

    # De-duplicate sources: the same page can be retrieved multiple times
    # by MMR. We surface each unique (source, page) pair exactly once,
    # preserving the retrieval order (most relevant first).
    seen: set[tuple] = set()
    sources: list[SourceDocument] = []
    for doc in raw_sources:
        meta = doc.metadata
        key = (meta.get("source", "unknown"), meta.get("page", 0))
        if key not in seen:
            seen.add(key)
            sources.append(
                SourceDocument(
                    source=meta.get("source", "Bilinmeyen Kaynak"),
                    page=meta.get("page", 0),
                    snippet=doc.page_content[:300],  # First 300 chars as preview
                )
            )

    elapsed = time.perf_counter() - t0
    log.info(f"Query resolved in {elapsed:.2f}s | Sources: {[s.source for s in sources]}")

    return AskResponse(answer=answer, sources=sources, query=request.query)


async def _invoke_chain(chain: any, query: str) -> dict:
    """
    Run the synchronous LangChain chain in a thread pool to avoid
    blocking FastAPI's async event loop.

    LangChain's RetrievalQA.invoke() is synchronous (it calls the Groq
    HTTP client internally). Running it directly in an async endpoint
    would block the entire server. run_in_executor offloads it to a
    worker thread, keeping the event loop free.
    """
    import asyncio
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, chain.invoke, {"query": query})