# ⚙️ Cep-Kampüs Backend (API & AI Engine)

This directory contains the Python backend, vector database setup, and AI infrastructure for the **Cep-Kampüs** project. It serves as the brain of the application, handling natural language processing, semantic search, and asynchronous API communication with the Flutter frontend.

## 🛠️ Tech Stack & Libraries
- **API Framework:** [FastAPI](https://fastapi.tiangolo.com/) (High-performance, async architecture)
- **Vector Database:** [ChromaDB](https://www.trychroma.com/) (Local, lightning-fast document embedding storage)
- **Large Language Model (LLM):** Meta Llama-3.3-70b-versatile (Accessed via Cloud API for heavy logical reasoning)
- **Embedding Model:** BGE-m3 (State-of-the-art multilingual vectorization)
- **Core Architecture:** RAG (Retrieval-Augmented Generation)

## 🧠 RAG Workflow & Hallucination Prevention
1. **Data Ingestion (`ingest.py`):** Official Iğdır University regulations (PDFs) are parsed, split into optimized 500-character chunks (with 50-character overlap to preserve context), and vectorized using BGE-m3.
2. **Semantic Retrieval:** When a student submits a query, the system searches the local ChromaDB using the **MMR (Maximal Marginal Relevance)** algorithm to fetch the most relevant, diverse, and non-redundant document chunks.
3. **Controlled Generation:** The retrieved context, along with a strict *System Prompt*, is sent to Llama 3.3. If the answer is not found in the provided context, the model is strictly instructed to trigger a **Fallback UI**, refusing to guess and instead providing the Student Affairs contact info.

## 🚀 Getting Started

### Prerequisites
- Python `>= 3.9`
- Valid API Key for the LLM provider (e.g., Groq/OpenAI)

### Installation & Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
    ```
Create and activate a virtual environment to isolate dependencies:
 ```
python -m venv venv
# On Mac/Linux:
source venv/bin/activate  
# On Windows:
venv\Scripts\activate
 ```
Install the required Python packages:
 ```
pip install -r requirements.txt
 ```
Environment Variables: Create a .env file in the root of the backend directory and add your API keys:
```
LLM_API_KEY=your_secret_api_key_here
```
⚡ Running the Server
Start the FastAPI server using Uvicorn with hot-reload enabled for development:
```
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Once running, the interactive API documentation (Swagger UI) will be automatically available at: http://localhost:8000/docs.
