# Tax Bunny — Phase 0: Production-Grade Flutter Foundation

Tax Bunny is a billing and business management platform designed for retail, wholesale, service, and trading businesses.

---

## Getting Started

### Prerequisites
- **Flutter SDK**: `^3.44.5`
- **Dart SDK**: `^3.12.2`

### Quick Setup
1. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```
2. **Environment Variables Configuration**:
   Create a `.env.development` file from `.env.example`:
   ```bash
   cp .env.example .env.development
   ```
3. **Run Application**:
   ```bash
   flutter run -d chrome  # Run on web
   flutter run            # Target native mobile / desktop emulators
   ```
4. **Run Verification Tests**:
   ```bash
   flutter test
   ```

---

## Project Structure

```text
lib/
├── app/          # Initializations, GoRouter definitions, Material 3 themes
├── core/         # Design system tokens, network client, local storage services, exceptions mapper, RBAC permissions, responsive utility
├── shared/       # Reusable components: custom buttons, input fields, tables, states screens
├── features/     # Feature-first domain folders (auth, onboarding, business, dashboard, subscription, notifications, settings)
└── main.dart     # Bootstrapping launcher
```

---

## Phase 0 Specifications Documents

For deeper details, consult our guidelines documents:
- 📖 [Architecture Details](ARCHITECTURE.md): Data flow, Routing redirect guards, Subscription Feature-Gating, and RBAC patterns.
- 🛠 [Development Setup Guidelines](DEVELOPMENT.md): Coding structures, style standards, and git commit guidelines.
- ⚙ [Environment Configuration Guide](ENVIRONMENT.md): Variables mappings, environment flags, and secrets instructions.
