# Tax Bunny Architectural Specifications

This document outlines the architectural specifications and design decisions implemented in Phase 0 of the **Tax Bunny Billing & Business Management Software**.

---

## 1. Feature-First Directory Structure

The project implements a scalable **feature-first** architecture. Common components and core utility systems are segregated into distinct modules.

- `lib/app/`: Central bootstrapping, route definitions (`GoRouter`), and global Material 3 theme configurations.
- `lib/core/`: Platform and framework utilities (design system constants, network client, local storage services, exceptions mapper, RBAC permissions, and responsive utilities).
- `lib/shared/`: Theme-aware reusable UI components (custom buttons, fields formatters, state screens, and tables).
- `lib/features/`: Isolated business modules following a Clean Architecture subset:
  - `data/`: Data sources, entities mappings, and repository implementations.
  - `domain/`: Business entities and access use cases.
  - `presentation/`: Pages, widgets, and state providers.

---

## 2. State Management (Riverpod)

State is managed globally and in a lifecycle-safe manner using **Riverpod 2.x**.
- `authProvider`: A `StateNotifierProvider` managing login status (`splash`, `unauthenticated`, `authenticated`) and caching session information.
- `businessProvider`: Tracks active business instances and switches current context parameters, updating local storage entries.
- `onboardingProvider`: Handles onboarding completion steps.
- `subscriptionProvider`: Tracks billing plan details (`Trial`, `Basic`, `Premium`, `Enterprise`) and resolves active feature capability gating.

---

## 3. Routing System (GoRouter)

Navigation is handled via **GoRouter**.
- Redirect guards evaluate authentication, onboarding progression, and active business selections before letting the user reach internal routes.
- Safe fallbacks handle 404 (Unknown routes) and coming-soon placeholders for modules that are scheduled for implementation in later phases.

---

## 4. Networking & Storage

- **Networking**: Built on a centralized **Dio** client (`ApiClient`). It is pre-configured with timeout thresholds, authorization Bearer interceptors, active business ID headers, and global exception mappers (`ErrorHandler`).
- **Storage**: Standard preferences use `SharedPreferences` (`StorageService`), while confidential credentials (like access tokens) use hardware-encrypted storage via `FlutterSecureStorage` (`SecureStorageService`).

---

## 5. Security & Access Rules

- **RBAC**: Implemented via `PermissionService` mapping user privileges (`UserRole`) to capability sets (`AppPermission`).
- **Feature Gating**: Controlled by the active subscription tier. Instead of checking plan names in the UI directly, components perform permission checks (e.g., `subscription.canAccess(SubscriptionFeature.pos)`). This keeps the UI decoupled from pricing plan changes.
