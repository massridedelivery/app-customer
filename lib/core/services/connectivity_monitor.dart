import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Internet reachability + quality. Ported from the driver app so both behave
/// the same (see driver `connectivity_monitor.dart`).
enum NetworkQuality {
  /// A probe is in flight and there's no prior verdict yet.
  checking,

  /// Reachable with acceptable latency.
  good,

  /// Reachable but slow/unstable — the "สัญญาณอ่อน" warning.
  weak,

  /// No network carrier, or the internet is unreachable.
  offline,
}

@immutable
class NetworkStatus {
  final NetworkQuality quality;

  /// Round-trip latency of the last successful probe, in ms.
  final int? latencyMs;

  /// True when the OS reports a network carrier (wifi/mobile/…), even if the
  /// internet itself turns out to be unreachable.
  final bool hasCarrier;

  /// True when the active transport is mobile data (for the label only).
  final bool isMobile;

  const NetworkStatus({
    this.quality = NetworkQuality.checking,
    this.latencyMs,
    this.hasCarrier = true,
    this.isMobile = false,
  });

  /// Whether to surface the alert banner (weak or offline).
  bool get isAlert =>
      quality == NetworkQuality.weak || quality == NetworkQuality.offline;

  NetworkStatus copyWith({
    NetworkQuality? quality,
    int? latencyMs,
    bool clearLatency = false,
    bool? hasCarrier,
    bool? isMobile,
  }) {
    return NetworkStatus(
      quality: quality ?? this.quality,
      latencyMs: clearLatency ? null : (latencyMs ?? this.latencyMs),
      hasCarrier: hasCarrier ?? this.hasCarrier,
      isMobile: isMobile ?? this.isMobile,
    );
  }
}

/// Monitors internet reachability + quality by probing the API host so the app
/// can warn on a weak or missing connection. Latency is a proxy for signal
/// strength (the OS exposes no cross-platform RSSI). Watched by the global
/// connectivity banner, so it runs app-wide.
class ConnectivityMonitor extends Notifier<NetworkStatus> {
  static const Duration _interval = Duration(seconds: 8);
  static const int _weakThresholdMs = 1200;
  static const Duration _probeTimeout = Duration(seconds: 6);

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  HttpClient? _client;
  bool _probing = false;

  @override
  NetworkStatus build() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      final isMobile = results.contains(ConnectivityResult.mobile);
      if (!hasNet) {
        state = NetworkStatus(
          quality: NetworkQuality.offline,
          hasCarrier: false,
          isMobile: isMobile,
        );
      } else {
        // Carrier just came back — re-probe to confirm real internet.
        state = state.copyWith(hasCarrier: true, isMobile: isMobile);
        _probe();
      }
    });

    _timer = Timer.periodic(_interval, (_) => _probe());

    ref.onDispose(() {
      _timer?.cancel();
      _sub?.cancel();
      _client?.close(force: true);
    });

    Future.microtask(_probe);
    return const NetworkStatus();
  }

  /// User-triggered re-check; flips to `checking` first so the UI shows motion.
  Future<void> refresh() async {
    state = state.copyWith(quality: NetworkQuality.checking);
    await _probe();
  }

  Future<void> _probe() async {
    if (_probing) return;
    _probing = true;
    try {
      final results = await Connectivity().checkConnectivity();
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      final isMobile = results.contains(ConnectivityResult.mobile);
      if (!hasNet) {
        state = NetworkStatus(
          quality: NetworkQuality.offline,
          hasCarrier: false,
          isMobile: isMobile,
        );
        return;
      }

      final client = _client ??= HttpClient()
        ..connectionTimeout = _probeTimeout;
      final uri = Uri.parse(ApiService.baseUrl);
      final sw = Stopwatch()..start();
      try {
        final req = await client.headUrl(uri).timeout(_probeTimeout);
        final resp = await req.close().timeout(_probeTimeout);
        await resp.drain<void>();
        sw.stop();
        final ms = sw.elapsedMilliseconds;
        // Any HTTP status means the host answered → internet is reachable.
        state = NetworkStatus(
          quality:
              ms > _weakThresholdMs ? NetworkQuality.weak : NetworkQuality.good,
          latencyMs: ms,
          hasCarrier: true,
          isMobile: isMobile,
        );
      } on TimeoutException {
        state = NetworkStatus(
          quality: NetworkQuality.offline,
          hasCarrier: true,
          isMobile: isMobile,
        );
      } on SocketException {
        state = NetworkStatus(
          quality: NetworkQuality.offline,
          hasCarrier: true,
          isMobile: isMobile,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('ConnectivityMonitor: probe error $e');
        state = NetworkStatus(
          quality: NetworkQuality.weak,
          hasCarrier: true,
          isMobile: isMobile,
        );
      }
    } finally {
      _probing = false;
    }
  }
}

final connectivityMonitorProvider =
    NotifierProvider<ConnectivityMonitor, NetworkStatus>(
      ConnectivityMonitor.new,
    );
