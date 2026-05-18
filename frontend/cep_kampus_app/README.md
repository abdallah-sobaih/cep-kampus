# 📱 Cep-Kampüs Mobile Application (Frontend)

This directory contains the source code for the **Cep-Kampüs** mobile application, built with [Flutter](https://flutter.dev/). It serves as the frontend interface for the Iğdır University AI assistant.

## 🛠️ Tech Stack & Libraries
- **Framework:** Flutter (Dart)
- **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod` & `riverpod_generator`)
- **Local Storage:** [SQLite](https://pub.dev/packages/sqflite) (for secure, offline chat history)
- **API Client:** [Dio](https://pub.dev/packages/dio) (for robust backend communication)
- **Voice Input:** `speech_to_text` (Configured for Turkish `tr_TR` native microphone support)
- **UI/UX Polish:** `flutter_markdown` (LLM response rendering), `google_fonts`, `lottie`

## 🏗️ Architecture Highlights
- **Reactive UI:** Leverages Riverpod for smooth, compile-safe state updates without rebuilding the entire widget tree, ensuring a lag-free chat experience.
- **Privacy-First:** User chat histories are saved strictly locally using SQLite. No chat logs are permanently stored on the external server.
- **Fault Tolerant:** Custom fallback UI and smooth error handling if the backend server is unreachable.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.3.0 <4.0.0`
- Android Studio / VS Code

### Installation & Run
1. Navigate to the frontend directory:
   ```bash
   cd frontend/cep_kampus_app
    ```
   Install all dependencies:
 ```
   flutter pub get
 ```
Run the app on your connected device or emulator:
 ```
flutter run
 ```
📦 Building the Release APK
To build the highly optimized, production-ready Android APK, use the following command.
(Note: The --no-tree-shake-icons flag is explicitly required to preserve dynamically rendered Material/Cupertino icons used within the chat interface).
 ```
flutter build apk --release --no-tree-shake-icons
 ```
The generated APK will be located at: build/app/outputs/flutter-apk/app-release.apk.
