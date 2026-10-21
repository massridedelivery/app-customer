import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks MainScreen to replay the home coach-mark tour (Account →
/// "ดูคำแนะนำการใช้งานหน้าแรก"). Each [request] bumps the count; MainScreen
/// listens, switches to the home tab and shows the tour again.
class HomeTourReplay extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final homeTourReplayProvider = NotifierProvider<HomeTourReplay, int>(
  HomeTourReplay.new,
);
