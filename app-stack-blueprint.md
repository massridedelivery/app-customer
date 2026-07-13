# Technical Architecture Blueprint

## 1. Tech Stack

- _Framework & Version_: Flutter (SDK >= 3.38.0)
- _State Management_: Riverpod (flutter_riverpod, riverpod_annotation, riverpod_generator)
- _Key Dependencies_:
  - _Navigation_: GoRouter (go_router)
  - _HTTP Client_: Dio (dio, talker_dio_logger)
  - _WebSocket_: WebSocketChannel (web_socket_channel)
  - _Dependency Injection_: GetIt & Injectable (get_it, injectable)
  - _Data Modeling_: Freezed & JSON Serializable (freezed, json_annotation)
  - _Local Storage_: Hive (hive_ce, hive_ce_flutter) & SharedPreferences

## 2. Project Structure

The project uses a _Feature-First Architecture_ inside the lib/ directory.

text
lib/
├── core/ # Shared generic modules
│ ├── configs/ # Environment, theme configurations
│ ├── constants/ # AppColors, AppTypography, AppSpacing
│ ├── data/ # Global data sources
│ ├── managers/ # Global state/logic managers
│ ├── navigation/ # Navigation utilities
│ ├── services/ # Core services (e.g., SocketService, ApiService)
│ └── utils/ # Helper functions
├── features/ # Feature modules
│ ├── auth/
│ ├── home/
│ ├── incoming_job/
│ │ ├── domain/ # Entities and Models (e.g., incoming_job_model.dart)
│ │ └── presentation/
│ │ ├── controllers/ # Riverpod controllers (e.g., incoming_job_controller.dart)
│ │ ├── screens/ # UI Pages
│ │ ├── states/ # Riverpod states
│ │ └── widgets/ # Reusable feature-level UI components
│ ├── job_live/
│ └── payment/
└── router/ # Application routing definitions
└── app_routes.dart # GoRouter configuration

_Naming Conventions_:

- _Directories & Files_: snake_case (e.g., incoming_job_controller.dart)
- _Classes_: PascalCase (e.g., IncomingJobController)
- _Variables & Methods_: camelCase (e.g., acceptJob())

## 3. Key Class Examples

### Service Class (WebSocket / API)

Services are standalone classes often wrapped in a Riverpod provider for DI and lifecycle management.

import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'socket_service.g.dart';

@riverpod
SocketService socketService(ref) {
final service = SocketService();
ref.onDispose(() => service.disconnect());
return service;
}

class SocketService {
WebSocketChannel? \_channel;
final String \_url = 'ws://echo.websocket.events';

void connect() {
if (\_channel != null) return;
try {
\_channel = WebSocketChannel.connect(Uri.parse(\_url));
\_channel!.stream.listen((data) {
// Handle incoming data
});
} catch (e) {
disconnect();
}
}

void disconnect() {
\_channel?.sink.close();
\_channel = null;
}
}

### State Management (Riverpod Controller)

Controllers use @riverpod annotations to generate providers automatically. They extend \_$ClassName and override the build() method to initialize state.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/states/incoming_job_state.dart';

part 'incoming_job_controller.g.dart';

@riverpod
class IncomingJobController extends \_$IncomingJobController {
@override
IncomingJobState build() {
return const IncomingJobState();
}

void receiveJob(IncomingJobModel job) {
state = state.copyWith(
currentJob: job,
isModalVisible: true,
);
}

void acceptJob() {
// Send acceptance to API/Socket
state = state.copyWith(isModalVisible: false, currentJob: null);
}
}

### Model / Data Class (Freezed)

Models are defined using the `@freezed` annotation for immutability, pattern matching, and JSON serialization.
**CRITICAL RULE**: Always use `abstract class` (e.g. `abstract class MyState with _$MyState`) when defining Freezed models. Do NOT use just `class`.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'incoming_job_model.freezed.dart';
part 'incoming_job_model.g.dart';

@freezed
sealed class IncomingJobModel with _$IncomingJobModel {
const IncomingJobModel._();

const factory IncomingJobModel({
required String jobId,
required String pickupAddress,
required String dropoffAddress,
required double netIncome,
required String paymentMethod,
required String serviceType,
}) = \_IncomingJobModel;

factory IncomingJobModel.fromJson(Map<String, dynamic> json) =>
\_$IncomingJobModelFromJson(json);
}
