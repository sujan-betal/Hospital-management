# 📱 Flutter Mobile App — AURA Medical Center

Companion **Flutter** client for the Hospital Management System, mirroring the web app against the same FastAPI backend.

## Quick Start

```bash
flutter pub get

# Defaults to the deployed backend; override for local development:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000  # iOS / desktop
```

## Architecture

Feature-first + layered:

| Layer | Responsibility |
|-------|----------------|
| `core/` | App-wide infrastructure — networking (`ApiClient`), theme, storage, utilities |
| `data/` | API sources, models, repository implementations (auth session) |
| `domain/` | Business entities, repository contracts, use cases |
| `features/` | Feature-specific UI and logic — `admin/`, `doctor/`, `receptionist/`, `patient/`, `auth/`, `dashboard/`, `profile/` |
| `routes/` | App navigation |
| `shared/` | Reusable widgets, extensions, enums, validators |
| `assets/` | Images, icons and fonts |
| `test/` | Unit / widget tests |

## Networking

All HTTP traffic flows through `lib/core/network/api_client.dart`:

- Base URL via `--dart-define=API_BASE_URL` (default: `https://hospital-management-96s6.onrender.com`)
- Attaches `Authorization: Bearer <JWT>` automatically
- Unwraps the `{ data, message, success }` envelope
- All **65 backend endpoints** are wired through the feature repositories

## Validation

```bash
flutter analyze
flutter test
```