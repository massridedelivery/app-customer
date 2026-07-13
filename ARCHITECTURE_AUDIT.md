# Architecture Audit: Flutter Customer App

## Overview
This document provides an analysis of the architectural patterns, folder structure, and data flow within the Customer App codebase as of May 2026.

## 1. Folder Structure Pattern: Feature-First
The project employs a **Feature-First** structure. Each business module is encapsulated within its own directory under `lib/features/`, promoting modularity and scalability.

### Structure within a Feature
A typical feature (e.g., `lib/features/auth/`) follows Clean Architecture layers:
- **presentation/**: Contains UI logic (Screens, Widgets) and State Management (Controllers, States).
- **domain/**: Contains business logic (UseCases) and abstractions (Repository Interfaces, Entities/Models).
- **data/**: Contains data retrieval logic (Repository Implementations, DataSources, Data Models).

### Core Layer
Shared logic and infrastructure are housed in `lib/core/`:
- `configs/`: Theme and app configurations.
- `constants/`: Global constants.
- `data/`: Shared data models and the `ApiRepository`.
- `error/`: Failure and exception handling logic.
- `managers/`: Global provider definitions.
- `services/`: Low-level services like `ApiService` (Dio wrapper).
- `utils/`: Common utility functions and extensions.

## 2. Dependency Injection
**Riverpod** is the exclusive mechanism for Dependency Injection (DI) and State Management.

- **Manual Providers**: Located in `lib/core/managers/providers.dart` for core services (e.g., `apiServiceProvider`, `tokenStorageProvider`).
- **Generated Providers**: Uses the `@riverpod` annotation (Riverpod Generator) for feature-specific controllers, repositories, and usecases.
- **Note on GetIt/Injectable**: While present in `pubspec.yaml`, they are currently not utilized in the active implementation.

## 3. Data Flow: UI to API Service
Data flow generally follows one of two patterns depending on the complexity of the feature.

### Pattern A: Clean Architecture (Complex Features)
Used in features like `auth` and the recently implemented `live_ride` (Driver Profile):
1. **UI (Screen/Widget)**: Observes state via a Riverpod Controller.
2. **Controller (`@riverpod`)**: Invokes a UseCase.
3. **UseCase**: Orchestrates business logic and calls a Repository interface.
4. **Repository (Implementation)**: Coordinates data retrieval, often calling a DataSource or the `ApiService`.
5. **DataSource**: Performs the actual network request using `ApiService`.
6. **ApiService**: Wraps `Dio` to handle headers, logging, and token refreshing.

### Pattern B: Simplified Service Pattern (Utility/Simple Features)
Used in features like `ride_booking`:
1. **UI**: Observes a Controller.
2. **Controller**: Calls the `ApiService` (via `apiServiceProvider`) or `ApiRepository` directly to perform operations.

## 4. Navigation & Routing
Handled by **GoRouter** (`lib/router/app_routes.dart`). It includes a `RouterNotifier` that listens to authentication states and active job status to handle complex redirects (e.g., forcing a user to the Live Ride screen if they have an active trip).

## 5. Coding Standards
- **Immutability**: Guaranteed using the `freezed` package for Models and States.
- **JSON Serialization**: Managed by `json_serializable`.
- **Code Generation**: Heavily utilized via `build_runner` for Riverpod, Freezed, and JSON logic.

## 6. Error Handling & Global State
How the app intercepts and presents errors to the user to maintain a consistent UX.
- **Network Errors**: Handled globally within the `ApiService` via Dio Interceptors (e.g., token expiration triggers an automatic logout or refresh).
- **Domain Failures**: Repositories map exceptions to Domain Models or throw specific custom Exceptions.
- **UI Error Presentation**: Controllers catch these exceptions using `AsyncValue.guard` and emit `AsyncError`. The UI listens to these states and displays standard Snackbars or Dialogs (avoiding direct `try-catch` inside widgets).

## 7. Backend Integration (BFF)
Understanding the API environment the app interacts with.
- The app primarily communicates with a **Backend-for-Frontend (BFF)** built with **Go (Golang)**. 
- API contracts are structured to serve mobile-specific views, meaning data mapping in the Flutter `data` layer should remain lightweight as the Go BFF already formats the payloads.