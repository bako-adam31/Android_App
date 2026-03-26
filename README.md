# 🌙 Sharqi – Fragrance Recommendation App

Sharqi is a modern mobile application built with Flutter that helps users discover perfumes through personalized recommendations, intelligent filtering, and an interactive swipe-based experience.

The app combines real-time API data, a custom backend, and a clean architecture to deliver a smooth and scalable user experience.

---

## 🚀 Features

- 🔐 **Authentication**
  - Firebase Authentication (Email & Password)
  - Auth state-based navigation

- 🔎 **Search**
  - Real-time perfume search with debounce
  - Detailed perfume pages with full information

- 🎯 **Personalized Recommendations**
  - "For You" section based on user preferences
  - Fallback logic when no personalized data is available

- 🔥 **Swipe Suggestions**
  - Tinder-like swipe system
  - Swipe right → add to favorites  
  - Swipe left → skip
  - Smart filtering:
    - removes seen items
    - excludes favorites
    - uses fallback levels (100 → 90 → 80)

- 🧠 **Finder (Smart Wizard)**
  - Multi-step note selection (citrus, woody, sweet, etc.)
  - Ranking system based on note matching

- 👤 **User Profile**
  - Editable bio, gender, favorite accord
  - Signature fragrance selection via search
  - Stored via custom backend (Firestore)

- ❤️ **Favorites**
  - Add/remove perfumes
  - Stored locally using SharedPreferences
  - Synced across screens

---

## 🏗️ Architecture

The project follows a clean and scalable structure:

- `models/` – data models  
- `services/` – API and business logic  
- `screens/` – UI and user interaction  

Key principles:
- Separation of concerns  
- Repository pattern  
- Service-based API handling  

---

## 🌐 Backend

Custom backend built with:
- Node.js + Express
- Firebase Admin SDK
- Firestore

Features:
- Authenticated API using Firebase ID tokens
- Profile management
- Favorites handling

---

## ⚡ Performance & Optimization

- Debounced search input
- Local caching with SharedPreferences
- Background processing using `compute()`
- Efficient swipe rendering (minimal rebuilds)

---

## 📦 Tech Stack

- Flutter
- Firebase Auth
- Node.js + Express
- Firestore
- REST API (fragrance data)

---

## 🛠️ Setup

```bash
flutter pub get
flutter run
