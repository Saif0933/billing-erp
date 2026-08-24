# Tax Bunny Environment Configurations

This project utilizes environment-specific files for variables, API endpoints, and client identities.

---

## 1. Environment Files

The following environment files are supported and must remain uncommitted:
- `.env.development`: Local development configs.
- `.env.staging`: QA, testing, and staging builds.
- `.env.production`: Live production variables.

Refer to `.env.example` for the reference schema.

---

## 2. Variables Definition

| Variable Name | Description | Example Value |
| --- | --- | --- |
| `API_BASE_URL` | Target backend REST API endpoint | `https://api-dev.taxbunny.com` |
| `ENVIRONMENT` | active configuration identifier (`development`, `staging`, `production`) | `development` |
| `APP_NAME` | Client-facing app title displayed in title bar | `Tax Bunny Dev` |

---

## 3. Bootstrapping Configurations

During initialization, `bootstrap.dart` reads and loads variables from `.env.development` (as default fallback).

To target a different file during builds:
```bash
flutter run --dart-define=ENV_FILE=.env.staging
```
