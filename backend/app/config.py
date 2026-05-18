from pathlib import Path
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # --- Paths ---
    BASE_DIR: Path = Path(__file__).resolve().parent.parent
    DOCUMENTS_DIR: Path = BASE_DIR / "data" / "documents"
    VECTORSTORE_DIR: Path = BASE_DIR / "vectorstore"

    # --- Chunking Parameters ---
    CHUNK_SIZE: int = 500
    CHUNK_OVERLAP: int = 50

    # --- Embedding ---
    EMBEDDING_MODEL: str = "BAAI/bge-m3"

    # --- ChromaDB ---
    CHROMA_COLLECTION_NAME: str = "cep_kampus_docs"

    # --- LLM ---
    GROQ_API_KEY: str = ""
    LLM_MODEL: str = "llama3-70b-8192"
    TOP_K_RETRIEVAL: int = 4

    # --- API Server ---
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000
    ALLOWED_ORIGINS: list[str] = ["*"]  # Tighten this in production

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()