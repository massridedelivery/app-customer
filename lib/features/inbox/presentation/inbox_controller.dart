import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/inbox/data/inbox_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InboxState {
  const InboxState({
    this.items = const [],
    this.unread = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<InboxItem> items;
  final int unread;

  /// The last page came back full, so there may be older messages.
  final bool hasMore;
  final bool loadingMore;

  InboxState copyWith({
    List<InboxItem>? items,
    int? unread,
    bool? hasMore,
    bool? loadingMore,
  }) => InboxState(
    items: items ?? this.items,
    unread: unread ?? this.unread,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// The signed-in customer's inbox. Guests have none (the endpoint needs an
/// account), so they get an empty state and the tab shows the login card.
/// Reloads when the app comes back to the foreground, so the tab badge picks
/// up campaigns that arrived while it was away.
class InboxController extends AsyncNotifier<InboxState> {
  static const pageSize = 20;

  @override
  Future<InboxState> build() async {
    ref.watch(authControllerProvider.select((s) => s.isAuthenticated));
    final lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(lifecycle.dispose);
    return _load();
  }

  Future<InboxState> _load() async {
    final signedIn = ref.read(authControllerProvider).isAuthenticated;
    if (!signedIn) return const InboxState();
    final r = await ref.read(inboxRepositoryProvider).fetch(limit: pageSize);
    return InboxState(
      items: r.items,
      unread: r.unread,
      hasMore: r.items.length >= pageSize,
    );
  }

  /// Infinite scroll: fetches the next page by offset and appends it,
  /// skipping ids already shown (a new message shifts the offsets by one).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final r = await ref
          .read(inboxRepositoryProvider)
          .fetch(limit: pageSize, offset: current.items.length);
      final latest = state.value ?? current;
      final seen = {for (final i in latest.items) i.id};
      state = AsyncData(
        latest.copyWith(
          items: [
            ...latest.items,
            ...r.items.where((i) => !seen.contains(i.id)),
          ],
          unread: r.unread,
          hasMore: r.items.length >= pageSize,
          loadingMore: false,
        ),
      );
    } catch (_) {
      // Keep what we have; scrolling to the end again retries.
      state = AsyncData((state.value ?? current).copyWith(loadingMore: false));
    }
  }

  Future<void> refresh() async {
    final next = await AsyncValue.guard(_load);
    // Keep showing what we had if a background refresh fails.
    if (next.hasValue || !state.hasValue) state = next;
  }

  /// Marks [item] read straight away on screen, then tells the server.
  Future<void> markRead(InboxItem item) async {
    final current = state.value;
    if (current == null || item.isRead) return;
    _setRead({item.id});
    try {
      await ref.read(inboxRepositoryProvider).markRead(item.id);
    } catch (_) {
      // Not fatal: the next refresh shows the server's view again.
    }
  }

  /// "อ่านทั้งหมดแล้ว": once the server agrees, every loaded row turns read
  /// and the badge drops to 0. Throws (nothing changes) if the call fails.
  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null) return;
    final ids = current.items.where((i) => !i.isRead).map((i) => i.id).toSet();
    await ref.read(inboxRepositoryProvider).markAllRead(loadedUnread: ids);
    _setRead(ids);
    final latest = state.value;
    if (latest != null) state = AsyncData(latest.copyWith(unread: 0));
  }

  /// Swipe to delete: drops [item] at once, then tells the server; puts it
  /// back in its place and rethrows if that fails.
  Future<void> delete(InboxItem item) async {
    final current = state.value;
    if (current == null) return;
    final index = current.items.indexWhere((i) => i.id == item.id);
    if (index < 0) return;
    final wasUnread = item.isRead ? 0 : 1;
    state = AsyncData(
      current.copyWith(
        items: [...current.items]..removeAt(index),
        unread: (current.unread - wasUnread).clamp(0, 1 << 30),
      ),
    );
    try {
      await ref.read(inboxRepositoryProvider).delete(item.id);
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items]
            ..insert(index.clamp(0, latest.items.length), item),
          unread: latest.unread + wasUnread,
        ),
      );
      rethrow;
    }
  }

  /// "ลบทั้งหมด" (the screen confirms first). Empties the list once the
  /// server has; throws and keeps everything if it fails.
  Future<void> deleteAll() async {
    if (state.value == null) return;
    await ref.read(inboxRepositoryProvider).deleteAll();
    state = const AsyncData(InboxState());
  }

  void _setRead(Set<String> ids) {
    final current = state.value;
    if (current == null) return;
    final now = DateTime.now();
    bool clears(InboxItem i) => ids.contains(i.id) && !i.isRead;
    final cleared = current.items.where(clears).length;
    final items = [
      for (final i in current.items) clears(i) ? i.copyWith(readAt: now) : i,
    ];
    state = AsyncData(
      current.copyWith(
        items: items,
        unread: (current.unread - cleared).clamp(0, 1 << 30),
      ),
    );
  }
}

final inboxControllerProvider =
    AsyncNotifierProvider<InboxController, InboxState>(InboxController.new);

/// Unread count for the tab badge (0 while loading / signed out / on error).
final inboxUnreadProvider = Provider<int>(
  (ref) => ref.watch(inboxControllerProvider).value?.unread ?? 0,
);

/// The "รับข่าวสารและโปรโมชั่น" (PDPA marketing consent) switch.
class MarketingOptInController extends Notifier<bool> {
  @override
  bool build() => ref.read(appStorageProvider).marketingOptIn;

  /// Flips the switch straight away, then saves it; reverts and rethrows if
  /// the backend refuses so the screen can say so.
  Future<void> set(bool optIn) async {
    final previous = state;
    state = optIn;
    try {
      await ref.read(inboxRepositoryProvider).setMarketingOptIn(optIn);
      await ref.read(appStorageProvider).setMarketingOptIn(optIn);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final marketingOptInProvider = NotifierProvider<MarketingOptInController, bool>(
  MarketingOptInController.new,
);
