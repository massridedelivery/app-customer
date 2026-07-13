# Customer App Implementation Plan

## 1. Overview & Tech Stack

The Customer App will share the same robust **Feature-First Architecture** as the Driver app to ensure maintainability and consistency.

- **Framework**: Flutter (SDK >= 3.38.0)
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)
- **Routing**: GoRouter
- **Network & Real-time**: Dio (`dio`, `talker_dio_logger`), WebSocketChannel (`web_socket_channel`)
- **Dependency Injection**: GetIt & Injectable
- **Data Modeling**: Freezed & JSON Serializable
- **Local Storage**: Hive (`hive_ce`, `hive_ce_flutter`) & SharedPreferences

## 2. Directory Structure (`lib/`)

Conforming to the overarching blueprint, the app will be divided into `core/` and specific customer `features/`.

```text
lib/
├── core/
│   ├── configs/       # Environment, theme configurations
│   ├── constants/     # Colors, Typography, Spacing
│   ├── data/          # Global data sources (Token storage)
│   ├── managers/      # Global state/logic managers (AuthManager)
│   ├── navigation/    # Navigation utilities
│   ├── services/      # ApiService (Dio), SocketService, LocationService
│   └── utils/         # Helper functions
├── features/
│   ├── auth/          # OTP, Login, Registration workflows
│   ├── home/          # Map View, Place Search, Current Location
│   ├── ride_booking/  # Fare Estimation, Promo entry, Payment selection
│   ├── ride_live/     # WebSocket stream mapping, Driver tracking, Ride Status
│   ├── payment/       # Omise Card setup
│   └── profile/       # User profile details & saved places management
└── router/
    └── app_routes.dart
```

## 2.1 Environment Setup

- **Environment Variables**: Define API base URL, WebSocket URL, and other constants in `core/configs/`.
- **Dependencies**: Ensure all dependencies are added to `pubspec.yaml` and run `flutter pub get`.

## 3. Core Features & Integration Workflows

### 3.1 Authentication Flow (Customer)

- **Endpoints**: `POST /api/auth/otp/send` & `POST /api/auth/otp/verify`. Role parameter must be `"customer"`.
- **Tokens**: Securely store `access_token` and `refresh_token` upon verification.
- **API Client**: Intercept all subsequent API requests to attach `Authorization: Bearer <access_token>`.

### 3.2 Home & Location Services

- **Map & Places**: Show user's current location on the map. Allow searching and selecting pickup and dropoff coordinates.
- **Service Selection**: New centralized hub mimicking Grab's format, redirecting to specific flows (`home` for rides).
- **Saved Places**: Manage customer's frequent spots via `GET /api/customer/places` and `POST /api/customer/places`.
- **Frequent Travel**: `GET /api/customer/places/frequent`
  - Returns recent/favorite destinations for quick access on the selection screen.
- **Recommended Food**: `GET /api/customer/food/recommended?lat={lat}&lng={lng}`
  - Returns a curated list of restaurants near the user.

### 3.3 Ride Booking Flow

- **Estimate Fare**: Call `POST /api/customer/jobs/estimate` using selected coordinates. Application will render distance, duration, and proposed fares.
- **Promo Validation**: Call `GET /api/customer/promo/validate?code=xyz` if the user applies a discount, dynamically updating the displayed fare.
- **Dispatch Route**: Submit ride via `POST /api/customer/jobs` passing exact coordinates, `payment_method` (`CASH`, `CARD`, or `PROMPTPAY`), and optional `promo_code`.
- **App State**: Transition the UI to a "Waiting for Driver" matching screen post-dispatch.

### 3.4 Live Ride Engine (WebSocket Integration)

- **Connection**: Connect securely to `ws://localhost:8080/ws?token=<access_token>`.
- **Keep-Alive**: Handle automatic closures, respond to PINGs (usually handled by the framework but needs verification), and implement exponential backoff for spontaneous disconnects.
- **Downstream Event Listeners**:
  - `job_accepted`: Extract assigned driver details. Transition UI to "Driver En-Route".
  - `driver_location`: Listen to real-time driver GPS coordinates to animate the car marker on the UI map.
  - `job_status`: Track status changes (`PICKED_UP`, `COMPLETED`, `CANCELLED`) to dynamically adjust the UI layout.

### 3.5 Rating & Payment

- **Card Saving**: Integrate Omise SDK to tokenize cards, then save securely via `POST /api/payment/card`.
- **Trip Completion**: Upon receiving the `COMPLETED` WebSocket event, seamlessly transition the user to a trip summary and rating screen.
- **Rating Dispatch**: Submit final rating via `POST /api/customer/jobs/:id/rate`.

## 4. Development Phases

- **Phase 1: Project Skeleton & Core Services (Completed)**
  - Scaffold `core/` structural modules (DI setup, Router, Theme).
  - Implement `ApiService` (Dio + Interceptors) and Data Storage.
  - Implement `auth` feature UI, connect OTP endpoints, and store tokens safely.
  - Implement refreshtoken mechanism.

- **Phase 2: Discovery & Booking Architecture (In Progress)**
  - Construct the `home` feature (Service Selection UI, Map, Google Places integration for lat/lng picking).
  - Build `ride_booking` flows (Fare estimation views, Payment method & Promo selector).
  - Connect the `POST /api/customer/jobs` integration.

- **Phase 3: Real-Time Engine (Live Ride)**
  - Implement `SocketService` mapped to Riverpod providers for live state propagation.
  - Build the `ride_live` feature (Interactive Live tracking UI).
  - Map dynamic WebSocket events (`job_accepted`, `driver_location`, `job_status`) tightly to UI animations and modals.

- **Phase 4: User Profile, Payments, and Polish**
  - Complete the `payment` feature by locking down Omise API integration.
  - Roll out `profile` feature screens (Edit contact details, Setup Places).
  - Implement End-of-Ride rating UI.
  - Handle edge-cases (e.g. app restart resume via fetching active job).

## 5. Acceptance Criteria

- **Build**: The application must be able to build successfully by using dart run build_runner build --delete-conflicting-outputs
- **Code Quality**: The application must be able to compile by using flutter analyze.
- **Version Control**: All code changes must be committed to the repository.
