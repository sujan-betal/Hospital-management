# Flutter Mobile App

Company-style Flutter structure for the Hospital Management project.

## Repository structure

- `backend/` - existing backend API
- `frontend/` - existing web application
- `flutter/` - Flutter mobile application

## Architecture

The mobile app follows a feature-first + layered architecture:

- `core/` - app-wide infrastructure, networking, theme, storage, utilities
- `data/` - API/data sources, models, repository implementations
- `domain/` - business entities, repository contracts, use cases
- `features/` - feature-specific UI and logic
- `routes/` - navigation
- `shared/` - reusable widgets, extensions, enums, validators
- `assets/` - images, icons and fonts
- `test/` - unit/widget tests

## Important

This ZIP contains the recommended source structure. After extracting it into the repository, run:

```bash
flutter create .
```

from inside the `flutter` directory to generate the standard Flutter platform files (`android/`, `ios/`, `web/`, etc.) and `pubspec.yaml`.
