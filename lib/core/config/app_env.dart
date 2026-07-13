/// Application environment (flavor) configuration.
///
/// Values are injected at build/run time via `--dart-define-from-file`
/// (see `env/dev.json` / `env/prod.json`). Each value falls back to a **dev**
/// default so a plain `flutter run` still works.
///
/// Usage:
///   flutter run --dart-define-from-file=env/dev.json --flavor dev
///   flutter build apk --dart-define-from-file=env/prod.json --flavor prod
enum Flavor { dev, prod }

abstract class Env {
  static const String _flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static Flavor get flavor => _flavor == 'prod' ? Flavor.prod : Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;
  static bool get isDev => flavor == Flavor.dev;

  /// REST API base URL (BFF).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://driver-api-dev.nutchaphut.dev',
  );

  /// WebSocket base URL (real-time updates).
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://driver-api-dev.nutchaphut.dev/ws',
  );

  /// Human-readable app name (used for logging / debug banners).
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Customer Dev',
  );

  /// Optional per-environment Google Places keys. When empty, the platform
  /// defaults baked into [GoogleConfig] are used instead.
  static const String googlePlacesKeyAndroid = String.fromEnvironment(
    'GOOGLE_PLACES_KEY_ANDROID',
    defaultValue: '',
  );
  static const String googlePlacesKeyIOS = String.fromEnvironment(
    'GOOGLE_PLACES_KEY_IOS',
    defaultValue: '',
  );
}
