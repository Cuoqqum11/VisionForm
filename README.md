# VisionForm

An advanced, real-time AI fitness and nutrition companion engineered to optimize workout form precision and personalize diet plan generation. Powered by high-speed device-level computer vision via MediaPipe for real-time skeletal orientation mapping alongside a resilient, multi-API AI engine that orchestrates dynamic meal recommendations. This application represents team **VisionForm's** exploration of combining cutting-edge edge computation with intelligent cloud-based LLM orchestration to provide a highly stable, interactive, and fault-tolerant health tracking platform.

## The Origin Story

The inspiration for this project originated from a core challenge prevalent in modern digital health systems: the fragmentation between motion tracking and cognitive health guidance. While many tools record passive workout counts, or provide generic static nutritional menus, few integrate real-time computer vision correction with personalized nutritional reasoning that remains resilient under any real-world connectivity limitations.

As the team at **VisionForm** observed during initial user evaluations:

> "Fitness isn't just about counting repetitions blindly, and nutrition isn't about scanning a static food spreadsheet. True physical transformation happens when real-time tracking accuracy meets highly responsive, reliable intelligence that stays active—whether you are in a premium gym environment or a remote offline space."

This core vision shaped the foundation of **VisionForm**. We didn't want to construct just another simple tracking application. Instead, we designed a resilient digital ecosystem where real-time MediaPipe computer vision analyzes physical performance, while a multi-API waterfall pipeline crafts dietary blueprints, supported by a specialized local persistence architecture that guarantees zero runtime failure.

## Overview

VisionForm is a Flutter-driven production-grade mobile application combining high-frequency edge pose estimation with adaptive backend routing. The application leverages custom real-time camera tracking streams to map skeletal landmarks, analyze motion trajectories (such as specific joint angle flexions in squats), count clean repetitions, and log detailed fault feedback records. Complementing the motion engine is a fully responsive diet tracking system featuring multi-database synchronization, contextual macro breakdown summaries, historical progression time-series graphs, and a resilient multi-API intelligence layout built to safeguard system stability during presentations and real-world deployment.

**Key Architectural Highlights:**
* **Resilient Manual Entry Interface:** To guarantee zero permission-related crashes or hardware incompatibilities during live evaluations, the diet ingestion UI utilizes a highly responsive manual text-input system with real-time chip generation, bypassing the need for volatile camera hardware access while maintaining a premium user experience.
* **Zero-Downtime AI Waterfall:** A cascaded network architecture ensures that if primary cloud nodes fail, the app seamlessly routes to secondary high-speed nodes or local rule-based engines without ever showing an error screen to the user.

## Technologies Used

### Frontend & Core App Mobile Framework
- **Flutter** - Cross-platform framework utilizing responsive functional components and custom asynchronous views.
- **Dart** - Multi-threaded object-oriented compilation supporting safe type-casting and direct platform hardware access.
- **Provider** - Centralized reactive state management architecture optimizing widget tree updates and service separation of concerns.
- **FL Chart** - Composable high-frequency mathematical charting framework used for historical analytical visualizations.

### Computer Vision & Core AI Infrastructure
- **MediaPipe Landmarker (`kwon_mediapipe_landmarker`)** - Fast, hardware-accelerated device-level skeletal landmark mapping.
- **Google Gemini AI (`flutter_gemini`)** - Primary semantic language model used for structural ingredient synthesis and customized meal blueprinting (`gemini-1.5-flash`).
- **Groq Service API (Meta Llama 3 Fallback)** - High-speed backup LLM ingestion stream handling request processing if primary nodes experience server limitations.
- **Rule-Based Resilient Engine** - Local static JSON ingestion fallbacks to protect user interfaces from ever experiencing connection interruptions or runtime crashes.

### Local Database Architecture & Persistence Layer
- **SQLite (`sqflite`)** - Multi-instance relational database architecture utilizing high-performance query compilation and schema indices.
- **`workout.db` (`DatabaseService`)** - Manages static asset tracking and chronological records mapping sets, duration, and notes.
- **`diet.db` (`DietDatabaseService`)** - Tracks comprehensive macro variables (Calories, Protein, Carbohydrates, Fats) organized into local timestamp sequences.
- **`visionform_v1.db` (`DatabaseHelper`)** - Purpose-built data warehouse logging real-time AI accuracy scores and rep counts for rolling historical evaluation metrics.

---

## Architecture & System Flow

### 1. Motion Tracking & Real-Time Computer Vision (`camera_tracking_ui.dart`)
- **Skeletal Overlay Mapping:** Implements a custom `_PoseOverlayPainter` which maps real-time coordinates over the camera viewport.
- **Joint Trajectory Evaluation:** Evaluates joint orientation state vectors dynamically (e.g., tracking the transition states of knee/hip angle flexions across a user repetition loop).
- **Session Capture Pipeline:** Automatically bundles tracking results, logs individual fault events into an explicit `FaultRecord` list, calculates average completion accuracy, and packages summaries into a unified `WorkoutSessionSummary` view.

### 2. Multi-API Intelligence Ingestion Waterfall (`diet_logic.dart`)
To ensure high system availability and zero downtime during performance evaluations, the application utilizes a cascaded network architecture for diet recommendations:

```text
[User Checked Ingredients]
│
▼
┌────────────────────┐
│  Primary Request   │ ──► Success ──► Parse JSON & Update UI
│ (Google Gemini AI) │
└──────────┬─────────┘
           │
           Fails (429 / Timeout)
           │
           ▼
┌────────────────────┐
│  Secondary Node    │ ──► Success ──► Parse JSON & Update UI
│ (Groq / Llama 3)   │
└──────────┬─────────┘
           │
           Fails (No Internet)
           │
           ▼
┌────────────────────┐
│  Resilient Local   │ ──► Instantly injects pre-formatted rule-based advice
│   Static Fallback  │     matching expected models. UI remains clean.
└────────────────────┘
```

### 3. Isolated Multi-Database Management
- **Conflict Resilience:** All insert transactions enforce continuous schema verification and apply `ConflictAlgorithm.replace` constraints to prevent transaction bottlenecks or structural lockouts.
- **Rolling Matrix Queries:** Leverages native SQL timeline filtering blocks (`DATE(created_at)`) to automatically isolate, average, and structure messy transaction history metrics directly into optimized time-series vectors for the main home page chart layout.

---

## Development & Setup Instructions

### Environment Prerequisites
- Flutter SDK (Stable Channel)
- Dart SDK
- Android SDK / iOS Xcode Build Layer

### Installation Execution

1. **Clone the codebase path repository:**
   ```bash
   git clone https://github.com/Cuoqqum11/VisionForm.git
   cd VisionForm
   git checkout Mimi
   ```

2. **Retrieve all package tracking configurations:**
   ```bash
   flutter pub get
   ```

3. **Establish your Environment Variables:**
   This project uses a `.env` file to securely manage API keys for Gemini and Groq.
   - Copy the provided example file:
     ```bash
     cp .env.example .env
     ```
     *(Note: On Windows, simply copy `.env.example` in your file explorer and rename it to `.env`)*
   - Open the newly created `.env` file and replace the placeholders with your actual API keys:
     ```env
     KEY=your_groq_api_key_here
     ```

4. **Compile and launch the application directly onto your test device:**
   ```bash
   flutter run
   ```

---
*VisionForm by VisionForm: Pioneering structural computer vision accuracy alongside zero-failure AI resilience engineering.*
