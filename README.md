# Android Project

## Student Information
**Name:** Bako Adam-Attila
**Course:** Android Development

## Project Title
Scent Finder - Perfume Recommendation App

## Description
A modern, cross-platform mobile application built with Flutter that helps users discover their perfect fragrance. The app features an interactive, Tinder-like "Swipe" mechanic where users can rate different fragrance notes (accords) and perfumes. Based on these preferences, the system provides personalized recommendations. The backend is powered by a Node.js/Express REST API and Firebase for secure data storage and user authentication.

## Features
- **Interactive Recommendation System:** A swipe-card interface to quickly rate perfumes and fragrance notes (`category_swipe_screen`).
- **User Authentication:** Secure registration and login using Firebase Authentication (JWT tokens).
- **Favorites Management:** Users can save their preferred fragrances and view them on their profile.
- **Search & Filter (Finder):** Browse the perfume database using text search and category filters.
- **Cloud Synchronization:** Real-time saving of user preferences and profile data to the Firestore database.

## Technologies Used
**Frontend (Mobile App):**
- Flutter SDK (Cross-platform UI framework)
- Dart Programming Language
- SharedPreferences (Local state & session storage)

**Backend (Server):**
- Node.js & Express.js (REST API framework)
- Firebase Admin SDK

**Database & Cloud:**
- Google Cloud Firestore (NoSQL Database)
- Firebase Authentication

## How to Run

To run this project, you need to have the Flutter SDK and Node.js installed on your machine.

## Setup and run the Backend

cd backend
# Install dependencies
npm install
# Create a .env file based on backend/.env.example with your Firebase credentials
# Start the server (defaults to port 3000)
npm start

##Setup and run the Mobile App (Flutter)
# Get Flutter dependencies
flutter pub get
# Run the app on a connected device or emulator
flutter run

##Suggested Code Organization
lib/
│
├── screens/                 # User Interface (UI) widgets and pages
│   ├── home_screen.dart
│   ├── login_screen.dart
│   └── category_swipe_screen.dart
│
├── services/                # Business logic, API calls, and state management
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── backend_api_service.dart
│
└── models/                  # Data classes (JSON serialization)
    ├── parfum.dart
    ├── profile_details.dart
    └── accord_category.dart

backend/src/
│
├── controllers/             # Handling HTTP requests and responses
├── routes/                  # REST API endpoint definitions
├── services/                # Database (Firestore) operations
└── middleware/              # Authentication (auth.js) and error handling



