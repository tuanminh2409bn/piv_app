# PIV App Project Context

## Project Overview
**Name:** `piv_app`
**Type:** Mobile Application (Flutter) with Firebase Backend.
**Purpose:** Likely a business/e-commerce application catering to multiple roles (Admin, Sales Rep, Accountant) with features for ordering, product management, and customer engagement.

## Technology Stack

### Mobile (Flutter)
-   **Framework:** Flutter (Dart 3.x)
-   **State Management:** `flutter_bloc`
-   **Dependency Injection:** `get_it`
-   **Functional Programming:** `dartz`
-   **Firebase Integration:**
    -   Auth (`firebase_auth`, Google/Facebook/Apple Sign-in)
    -   Firestore (`cloud_firestore`)
    -   Storage (`firebase_storage`)
    -   Functions (`cloud_functions`)
    -   Messaging (`firebase_messaging`)
-   **UI Components:** Material Design, `carousel_slider`, `flutter_fortune_wheel`.

### Backend (Firebase Cloud Functions)
-   **Language:** TypeScript
-   **Runtime:** Node.js 18
-   **Location:** `functions/` directory
-   **Dependencies:** `firebase-admin`, `firebase-functions`.

## Architecture
The project follows a **Feature-Based Architecture**.
Key directories:
-   `lib/features/`: Contains feature-specific code.
    -   *Commerce:* `products`, `cart`, `checkout`, `orders`, `quick_order`, `returns`, `vouchers`, `wishlist`.
    -   *Roles:* `admin`, `sales_rep`, `accountant`.
    -   *Engagement:* `lucky_wheel`, `news`, `notifications`.
    -   *Core:* `auth`, `profile`, `main`, `search`.
-   `lib/core/`: Likely contains shared services, error handling, and DI setup.
-   `lib/common/`: Shared widgets and utilities.
-   `lib/data/`: Data models (likely shared or base repositories).

## Development Conventions

### Code Style
-   **Linting:** `flutter_lints` is used for Dart. ESLint (Google config) is used for TypeScript functions.
-   **State Management:** BLoC pattern (Events, States, Blocs).
-   **Naming:** Snake_case for files, PascalCase for classes, camelCase for variables/methods.

### Build & Run Commands

**Flutter:**
-   Run App: `flutter run`
-   Get Dependencies: `flutter pub get`
-   Run Tests: `flutter test`
-   Build APK (Android): `flutter build apk`
-   Build iOS: `flutter build ios`

**Firebase Functions:**
-   Navigate to directory: `cd functions`
-   Install Deps: `npm install`
-   Build (TS to JS): `npm run build`
-   Lint: `npm run lint`
-   Deploy: `firebase deploy --only functions`

## Key Files
-   `lib/main.dart`: Application entry point.
-   `pubspec.yaml`: Flutter dependencies and configuration.
-   `functions/src/index.ts`: Entry point for Cloud Functions.
-   `firebase.json`: Firebase configuration.
-   `lib/firebase_options.dart`: Firebase initialization options (generated).
