import 'package:customer_app/features/profile/data/datasources/account_remote_data_source.dart';
import 'package:customer_app/features/profile/domain/models/my_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "ข้อมูลของฉัน" screen's data. Loaded when the screen opens and dropped
/// when it closes, so the customer's data doesn't sit in memory afterwards.
/// Errors are [DataExportException]s.
class MyDataController extends AsyncNotifier<MyData> {
  @override
  Future<MyData> build() async => MyData.fromJson(
    await ref.read(accountRemoteDataSourceProvider).exportData(),
  );

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// "ดูเพิ่มเติม": appends the next page of [key]. On failure keeps what is
  /// shown and rethrows the [DataExportException] for the screen to report.
  Future<void> loadMore(String key) async {
    final current = state.value?.section(key);
    if (current == null || !current.hasMore || current.loadingMore) return;
    _put(current.copyWith(loadingMore: true));
    try {
      final next = await ref
          .read(accountRemoteDataSourceProvider)
          .exportSection(key, page: current.page + 1, limit: current.limit);
      _put(current.append(next));
    } catch (_) {
      _put(current);
      rethrow;
    }
  }

  void _put(MyDataSection section) {
    final data = state.value;
    if (data != null) state = AsyncData(data.withSection(section));
  }
}

final myDataControllerProvider =
    AsyncNotifierProvider.autoDispose<MyDataController, MyData>(
      MyDataController.new,
      // No automatic retries: a failure shows its error (a 429 with its wait)
      // and the customer retries from there.
      retry: (_, _) => null,
    );
