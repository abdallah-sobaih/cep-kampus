<div align="center">
  <img src="https://raw.githubusercontent.com/abdallah-sobaih/cep-kampus/main/frontend/cep_kampus_app/assets/icon/logo.png" width="120" alt="Cep-Kampüs Logo">
</div>

  <h1>🎓 Cep-Kampüs</h1>
  <p><b>Next-Generation AI-Powered Campus Assistant for Iğdır University Students</b></p>

  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=FastAPI&logoColor=white" />
  <img src="https://img.shields.io/badge/ChromaDB-FD6F46?style=for-the-badge&logo=Chroma&logoColor=white" />
  <img src="https://img.shields.io/badge/Meta_Llama_3.3-0467DF?style=for-the-badge&logo=meta&logoColor=white" />
</div>

<br/>

> **Cep-Kampüs** is an intelligent, **RAG (Retrieval-Augmented Generation)** based mobile application that scans complex university regulations in seconds, converts speech to text, and strictly grounds every answer in official academic sources.

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🎙️ **Voice Commands (STT)** | Ask your questions directly via voice instead of typing, with full Turkish language support. |
| 📚 **Source Transparency** | Zero AI hallucinations! Every answer includes a clickable "Tag" showing the exact document name and page number. |
| 🛡️ **Anti-Hallucination** | For non-university questions, the AI gracefully apologizes and provides the official Student Affairs contact information instead of fabricating an answer. |
| 🌙 **Modern UI/UX** | Eye-friendly Dark Mode, fluid Riverpod state management, and highly secure local SQLite chat history. |

---

## 🧠 System Architecture & Technologies

Cep-Kampüs is designed and developed following strict **Clean Architecture** principles.

### 📱 Frontend (Mobile App)
- **Flutter:** Cross-platform (Android & iOS) fluid UI.
- **Riverpod:** Compile-safe and performant State Management.
- **SQLite:** Local data persistence (`sqflite`) to ensure maximum user privacy.

### ⚙️ Backend & AI
- **FastAPI (Python):** Asynchronous, high-speed data processing and API routing.
- **ChromaDB:** Local Vector Database storing official PDFs divided into optimized 500-character chunks.
- **BGE-m3 Embedding:** Multilingual, high-precision text vectorization model.
- **Llama-3.3-70b-versatile:** A powerful Large Language Model hosted via Cloud API (Groq), providing GPT-4 level logical reasoning without burning local hardware.
- **MMR Algorithm:** Maximal Marginal Relevance filtering for the most diverse and accurate search results.

---

## 🚀 Local Development Setup

Follow these steps to run the project locally. 
*(Note: For security reasons, the `.env` file containing API Keys and the `ChromaDB` vector files are not included in this repository).*

**1. Starting the Backend (Server):**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # For Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
2. Starting the Frontend (Mobile App):
```
cd frontend/cep_kampus_app
flutter pub get
flutter run
```
👨‍💻 Developer Team
This project was developed by the Engineering team at Iğdır University under the supervision of Dr.ogr. gültekin ışık:

💻 Abdallah Sobaih *

🎨 Hiba Aldershawi

🚀 Rama Almekhlif

⚙️ Nabil Al Rahmoun
