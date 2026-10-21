import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/inbox/data/inbox_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InboxState {
  const InboxState({this.items = const [], this.unread = 0});

  final List<InboxItem> items;
  final int unread;
}

/// The signed-in customer's inbox. Guests have none (the endpoint needs an
/// account), so they get an empty state and the tab shows the login card.
/// Reloads when the app comes back to the foreground, so the tab badge picks
/// up campaigns that arrived while it was away.
class InboxController extends AsyncNotifier<InboxState> {
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
    final r = await ref.read(inboxRepositoryProvider).fetch();
    return InboxState(items: r.items, unread: r.unread);
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

  /// "อ่านทั้งหมดแล้ว" — the API marks one at a time, so send each unread id.
  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null) return;
    final ids = current.items.where((i) => !i.isRead).map((i) => i.id).toSet();
    if (ids.isEmpty) return;
    _setRead(ids);
    final repo = ref.read(inboxRepositoryProvider);
    await Future.wait(
      ids.map((id) => repo.markRead(id).catchError((_) {})),
    );
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
      InboxState(
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
