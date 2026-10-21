import 'package:customer_app/core/managers/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One message in the in-app inbox: a marketing campaign the admin sent (the
/// same message also went out as a push), kept here to read back later.
class InboxItem {
  const InboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;

  /// Campaign payload: `deeplink` (the app path to open), `screen` (its name,
  /// e.g. promo / referral / ride_landing), plus screen-specific ids.
  final Map<String, String> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  /// The app path to open on tap, or null when there's nowhere to go (home).
  String? get deeplink {
    final raw = data['deeplink'] ?? data['route'];
    if (raw == null || !raw.startsWith('/') || raw == '/' || raw == '/main') {
      return null;
    }
    return raw;
  }

  String get screen => data['screen'] ?? '';

  InboxItem copyWith({DateTime? readAt}) => InboxItem(
    id: id,
    title: title,
    body: body,
    data: data,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
  );

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return InboxItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: rawData is Map
          ? rawData.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// `GET /api/notifications?limit&offset` → a page (newest first) + unread count;
/// `PATCH /api/notifications/{id}/read`. Both need a signed-in customer.
class InboxRepository {
  InboxRepository(this._dio);

  final Dio _dio;

  Future<({List<InboxItem> items, int unread})> fetch({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/api/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = res.data as Map<String, dynamic>;
    final raw = data['items'];
    final items = raw is List
        ? raw.whereType<Map<String, dynamic>>().map(InboxItem.fromJson).toList()
        : <InboxItem>[];
    final unread =
        (data['unread_count'] as num?)?.toInt() ??
        items.where((i) => !i.isRead).length;
    return (items: items, unread: unread);
  }

  /// `PATCH /api/notifications/prefs` — opting out stops campaign pushes and
  /// inbox entries (order-status notifications still arrive).
  Future<void> setMarketingOptIn(bool optIn) => _dio.patch(
    '/api/notifications/prefs',
    data: {'marketing_opt_in': optIn},
  );

  Future<void> markRead(String id) =>
      _dio.patch('/api/notifications/${Uri.encodeComponent(id)}/read');
}

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(ref.watch(apiServiceProvider).dio),
);
