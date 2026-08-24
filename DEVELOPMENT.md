# Tax Bunny Development Guidelines

This document provides setup and contribution instructions for developers working on the Tax Bunny Flutter codebase.

---

## 1. Setup & Installation

### Prerequisites
- Flutter SDK: `^3.44.5`
- Dart SDK: `^3.12.2`

### Run Environment
1. Get packages:
   ```bash
   flutter pub get
   ```
2. Copy environment file configurations (e.g. from `.env.example` to `.env.development`):
   ```bash
   cp .env.example .env.development
   ```
3. Run the application:
   ```bash
   flutter run -d chrome  # Web testing
   flutter run            # Target active mobile / desktop emulator
   ```

---

## 2. Directory and Code Conventions

When adding a new feature (e.g. `pos`), follow this layout:
```text
lib/features/pos/
├── data/
│   ├── datasources/  # Remote APIs / Local databases
│   └── models/       # Serialization models
├── domain/
│   └── entities/     # Pure Dart models
└── presentation/
    ├── pages/        # Main screens
    └── providers/    # Riverpod state notifiers
```

### Formatting
- Use standard lint rules defined in `analysis_options.yaml`.
- Run formatting check before committing:
  ```bash
  flutter format lib/
  ```

---

## 3. Git Commit Standards

Follow conventional commits syntax:
- `feat`: introducing a new feature
- `fix`: bug fixes
- `refactor`: structural updates without change in behavior
- `docs`: updates in documentation files
- `test`: adding/modifying tests
- `chore`: updating settings, dependencies or CI/CD pipelines
