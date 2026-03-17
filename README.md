# Fragrance App 💎

A modern, interactive Android fragrance discovery application built with Flutter, Firebase, and a custom Node.js backend. 

---

## 🚀 Overview

This application redefines how users discover perfumes by providing an engaging, personalized, and intuitive experience. By combining modern UI paradigms with smart filtering, the app acts as a digital scent consultant.

The system architecture leverages **Firebase Authentication** for secure access, a **custom Node.js backend** for logic processing, and an external fragrance API to deliver a rich database of perfumes.

---

## ✨ Key Features

### 🏠 Home Dashboard
* **Curated Collections:** Browse fragrances by specialized categories such as Niche, Designer, Gourmand, and Citrusy.
* **Daily Spotlights:** Get personalized daily suggestions (e.g., highlighting specific brands like Tom Ford).
* **History Tracking:** Quickly access recently viewed perfumes.

### 🔥 Interactive Suggestions (Tinder-Style)
* **Engaging Discovery:** Swipe right to save a perfume to your favorites, or swipe left to skip.
* **Fluid UI/UX:** Features smooth, interactive card animations.
* **Targeted Swiping:** Filter your swipe queue based on specific fragrance categories.

### 🔎 Smart Fragrance Finder
* **Note-Based Search:** A multi-step selection process allowing users to choose preferred base, heart, and top notes (e.g., Citrus, Fruity, Oriental).
* **Intelligent Matching:** Finds and recommends perfumes that align with the selected notes.
* **Similarity Ranking:** Results are ranked dynamically based on note similarity rather than strict exact matches, providing better recommendations.

### ❤️ Persistent Favorites System
* **Personalized Library:** Users can manage their own curated list of favorite scents.
* **Cloud Synchronization:** Favorites are securely synced via the custom backend using the user's Firebase UID, ensuring data persists across app restarts and multiple devices.

### 👤 Secure Authentication
* **Powered by Firebase:** Reliable and secure user registration and login flows.
* **UID Integration:** Seamlessly connects the authenticated user's Firebase UID with the custom Node.js database operations.

---

## 🏗️ System Architecture

The application follows a clean, decoupled client-server architecture:

```text
📱 Flutter Client App
        │
        ├── Authenticates ──➔ 🔐 Firebase Auth
        │
        └── API Requests (w/ UID token)
                │
                ▼
⚙️ Node.js Backend (Express)
        │
        └── Reads/Writes ──➔ 🗄️ Firestore Database
