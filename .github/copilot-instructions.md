# CoisaRápida AI Coding Instructions

## Project Overview
CoisaRápida is a full-stack platform for urban item rentals and deliveries, built with Flutter (mobile app) and NestJS (backend API). The system integrates Firebase for authentication, real-time features, and file storage with a PostgreSQL database for complex business logic.

## Architecture

### Frontend (Flutter)
- **Structure**: Feature-based architecture under `lib/features/`
  - `data/`: Repositories, models
  - `domain/`: Entities, use cases, abstractions
  - `presentation/`: Widgets, providers, UI logic
- **State Management**: Riverpod with code generation (`riverpod_annotation`)
- **Navigation**: GoRouter for declarative routing
- **Backend Integration**: Firebase (Auth, Firestore, Storage, Messaging)
- **Key Dependencies**: `flutter_riverpod`, `go_router`, `firebase_*`, `google_maps_flutter`

### Backend (NestJS)
- **Structure**: Domain-Driven Design (DDD) under `src/`
  - `core/`: Shared infrastructure (auth, database, notifications)
  - `domains/`: Business domains (usuario, item, aluguel, conversa, etc.)
  - `infrastructure/`: External integrations and persistence
  - `presentation/`: Controllers, DTOs, guards
- **Database**: PostgreSQL with TypeORM
- **Authentication**: Firebase tokens validated via JWT strategy
- **Key Dependencies**: `@nestjs/*`, `typeorm`, `firebase-admin`, `pg`

## Critical Workflows

### Development Setup
```bash
# Frontend
flutter pub get
flutter run

# Backend
npm install
docker-compose up -d  # For PostgreSQL
npm run start:dev
```

### Database Operations
- Use `docker-compose.yml` for local PostgreSQL
- Migrations in `src/modules/shared/infra/migrations/`
- Entities follow DDD aggregates (Usuario, Item, Aluguel as roots)

### Firebase Integration
- Configure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Backend uses `firebase-admin` for server-side operations
- Auth providers: Email/password, Google, Apple

## Project Conventions

### Naming Patterns
- **Entities**: PascalCase (e.g., `Usuario`, `Item`)
- **DTOs**: Suffix with `Dto` (e.g., `CreateUsuarioDto`)
- **Services**: Suffix with `Service` (e.g., `UsuarioService`)
- **Modules**: PascalCase with `Module` (e.g., `UsuarioModule`)

### DDD Implementation
- Each domain in `src/domains/{domain}/` with entities, repositories, services
- Repositories have interfaces in `repositories/interfaces/` and implementations in `implementations/`
- Use domain events for cross-aggregate communication

### Flutter Patterns
- Riverpod providers in `presentation/` folders
- Use `AsyncValue` for loading/error states
- Localization keys in `lib/l10n/` (Portuguese/English)

### Error Handling
- Backend: Custom exceptions in `src/core/shared/errors/`
- Frontend: `AsyncValue` guards and error widgets
- Validation: `class-validator` decorators on DTOs

## Integration Points

### Firebase ↔ PostgreSQL Sync
- Firebase Auth creates users, backend syncs to PostgreSQL `usuarios` table
- Use `AuthProvider` entity to link Firebase UIDs to local users
- Session management via JWT tokens from Firebase custom claims

### Cross-Component Communication
- Backend publishes events for real-time updates to Firestore
- Frontend listens to Firestore changes for live data
- Push notifications via Firebase Messaging

## Key Files to Reference
- `pubspec.yaml`: Flutter dependencies and config
- `package.json`: Backend dependencies
- `src/app.module.ts`: Main NestJS module imports
- `src/data-source.ts`: TypeORM configuration
- `lib/core/config/firebase_config.dart`: Firebase setup
- `backend/DATABASE_DDD_STRUCTURE.md`: Database schema overview
- `backend/NESTJS_DDD_MODULES.md`: Module organization

## Common Patterns

### Adding New Domain (Backend)
1. Create `src/domains/{domain}/` structure
2. Define entities with TypeORM decorators
3. Implement repository interface and TypeORM implementation
4. Create service with business logic
5. Add controller with validation DTOs
6. Register in domain module and import in `app.module.ts`

### Adding New Feature (Frontend)
1. Create `lib/features/{feature}/` with data/domain/presentation layers
2. Define models and repository implementations
3. Create Riverpod providers for state management
4. Build UI components and pages
5. Add routes in `lib/core/config/routes.dart`

### Database Queries
- Use TypeORM query builder for complex queries
- Prefer repository methods over direct entity access
- Include relations explicitly with `.relations()` or `join` options

### Testing
- Backend: Jest with `npm run test`
- Frontend: Flutter tests with `flutter test`
- E2E: `npm run test:e2e` for API tests