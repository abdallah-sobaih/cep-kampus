"""
schemas.py — Pydantic models for API request/response validation.
"""

from pydantic import BaseModel, Field


class AskRequest(BaseModel):
    """Payload sent by the Flutter client."""
    query: str = Field(
        ...,
        min_length=3,
        max_length=1000,
        description="The student's question in Turkish or English.",
        examples=["Mazeret sınavına kimler girebilir?"],
    )

class SourceDocument(BaseModel):
    """A single retrieved source chunk, surfaced to the user as a citation."""
    source: str = Field(description="PDF filename (e.g. 'lisans_egitim_yonetmeligi.pdf')")
    page: int = Field(description="1-indexed page number within the source document.")
    snippet: str = Field(description="The exact text chunk the answer was derived from.")


class AskResponse(BaseModel):
    """Full response returned to the Flutter client."""
    answer: str = Field(description="The LLM-generated answer, grounded in retrieved context.")
    sources: list[SourceDocument] = Field(
        description="Ordered list of source documents used to generate the answer.",
        default_factory=list,
    )
    query: str = Field(description="The original query, echoed back for client-side logging.")