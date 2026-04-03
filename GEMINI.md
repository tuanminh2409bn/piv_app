# PIV App Project Context

## Project Overview
**Name:** `piv_app`
**Type:** Flutter Multi-platform Application (Mobile & Web) with Firebase Backend.
**Purpose:** Business/e-commerce application catering to multiple roles (Admin, Sales Rep, Accountant, Agent) with features for ordering, product management, and customer engagement.

## Technology Stack

### Frontend (Flutter)
-   **Framework:** Flutter (Dart 3.x)
-   **Platforms:** Android, iOS, Web (Firebase Hosting)
-   **State Management:** `flutter_bloc`
-   **Dependency Injection:** `get_it`
-   **Functional Programming:** `dartz`
-   **Firebase Integration:**
    -   Auth (`firebase_auth`, Google/Facebook/Apple Sign-in)
    -   Firestore (`cloud_firestore`)
    -   Storage (`firebase_storage`)
    -   Functions (`cloud_functions`)
    -   Messaging (`firebase_messaging`)
-   **UI Components:** Material Design, `carousel_slider`, `flutter_fortune_wheel`, `flutter_animate`.

### Backend (Firebase Cloud Functions)
-   **Language:** TypeScript
-   **Runtime:** Node.js 18
-   **Location:** `functions/` directory
-   **Dependencies:** `firebase-admin`, `firebase-functions`.

## Architecture
The project follows a **Feature-Based Architecture**.
Key directories:
-   `lib/features/`: Contains feature-specific code.
-   `lib/core/`: Shared services, platform utilities, error handling, and DI setup.
-   `lib/common/`: Shared widgets (Responsive wrappers, Network images, etc.).
-   `lib/data/`: Shared data models and base repositories.

## Web Development Rules & Progress

### Core Mandate
> **WEB DEVELOPMENT MUST NOT BREAK MOBILE CODE.** 
> All changes for Web must be "surgical", ensuring zero regression for the existing Android/iOS applications.

### Development Progress (as of April 2026)
1.  **Platform Abstraction:** Implemented `PlatformUtils` and `PlatformXImage` using **Conditional Imports** to prevent `dart:io` crashes on Web.
2.  **Responsive Foundation:** Created `Responsive` helper and `ResponsiveWrapper` to manage layouts across different screen sizes.
3.  **Entry Point Separation:** 
    -   `lib/main.dart`: Dedicated for Mobile.
    -   `lib/main_web.dart`: Dedicated for Web (optimized, no mobile-only plugins).
4.  **UI Optimization:** 
    -   Full-width backgrounds for Login, Register, and Profile pages on Web.
    -   Centered, constrained content (max-width) for forms and lists.
    -   Adaptive layouts (2-column forms, dynamic grid counts) for Web.
5.  **Security Rules:** Updated `firestore.rules` to allow Sales Reps and Accountants to propose price/discount changes for pending agents (Admin approval workflow).

### Web Best Practices
-   **Use `PlatformUtils`:** Instead of `dart:io` or `Platform.is...`, use `PlatformUtils.isWeb/isAndroid/isIOS`.
-   **Adaptive UI:** Use `Responsive.value(context, mobile: x, desktop: y)` for dynamic values (grid counts, aspect ratios).
-   **Responsive Wrapping:** Wrap screen content in `ResponsiveWrapper` to prevent horizontal stretching on wide screens.
-   **Image Handling:** Use `AppNetworkImage` for all network images to ensure better loading/error handling on Web.
-   **Firebase Storage:** Ensure CORS is configured (`cors.json`) and build with `--web-renderer html` if images fail to load.

## Development Conventions

### Code Style
-   **Linting:** `flutter_lints` for Dart.
-   **State Management:** BLoC/Cubit pattern (Events, States, Blocs).
-   **Naming:** snake_case for files, PascalCase for classes, camelCase for variables/methods.

### Build & Run Commands

**Flutter Mobile:**
-   Run: `flutter run`
-   Build APK: `flutter build apk`
-   Build iOS: `flutter build ios`

**Flutter Web:**
-   Run: `flutter run -d chrome --web-renderer html -t lib/main_web.dart`
-   Build: `flutter build web --web-renderer html -t lib/main_web.dart`
-   Deploy: `firebase deploy --only hosting`

**Firebase Backend:**
-   Deploy Rules: `firebase deploy --only firestore:rules`
-   Deploy Functions: `firebase deploy --only functions`

## Key Files
-   `lib/main.dart` & `lib/main_web.dart`: App entry points.
-   `lib/core/utils/platform_utils.dart`: Platform detection.
-   `lib/common/widgets/responsive_wrapper.dart`: Web layout guard.
-   `firestore.rules`: Security configurations.
-   `firebase.json`: Hosting and project config.
