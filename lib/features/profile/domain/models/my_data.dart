/// The customer's own data from `GET /api/customer/export`, for the
/// "ข้อมูลของฉัน" screen (PDPA right of access).
///
/// Sections stay close to the JSON: the screen picks the fields it shows, and
/// [MyData.toJson] gives the customer back what the server sent (plus any
/// pages loaded since) when they share it. Personal data end to end: never log
/// it or hand it to analytics or crash reporting.
library;

/// Section keys this app version knows how to show, in the order the backend
/// lists them. A key the server adds later is skipped until the app learns it.
const knownMyDataSections = {
  'profile',
  'notification_prefs',
  'saved_places',
  'trips',
  'orders',
  'loyalty',
  'points_history',
  'search_history',
  'consents',
};

/// The long histories: they arrive with their newest page and page through
/// `GET /api/customer/export/{section}`.
const pagedMyDataSections = {
  'trips',
  'orders',
  'points_history',
  'search_history',
};

class MyDataSection {
  const MyDataSection({
    required this.key,
    required this.title,
    required this.data,
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  factory MyDataSection.fromJson(String key, Map<String, dynamic> json) =>
      MyDataSection(
        key: key,
        title: (json['title'] as String?) ?? key,
        data: json,
        items: _maps(json['items']),
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
        total: (json['total'] as num?)?.toInt() ?? _maps(json['items']).length,
        hasMore: json['has_more'] == true,
      );

  final String key;

  /// Thai heading from the server, shown as is.
  final String title;

  /// The section object as received (single-object sections read from it).
  final Map<String, dynamic> data;

  /// The rows of a list section, every page loaded so far.
  final List<Map<String, dynamic>> items;

  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  /// The next page is on its way (only that section's button spins).
  final bool loadingMore;

  bool get isPaged => pagedMyDataSections.contains(key);

  /// A list section (has `items`), as opposed to profile / prefs / loyalty.
  bool get isList => data.containsKey('items');

  /// This section with the next page from the paging route appended.
  MyDataSection append(Map<String, dynamic> next) {
    final more = MyDataSection.fromJson(key, next);
    return MyDataSection(
      key: key,
      title: title,
      data: data,
      items: [...items, ...more.items],
      page: more.page,
      limit: more.limit,
      total: more.total,
      hasMore: more.hasMore,
    );
  }

  MyDataSection copyWith({bool? loadingMore}) => MyDataSection(
    key: key,
    title: title,
    data: data,
    items: items,
    page: page,
    limit: limit,
    total: total,
    hasMore: hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  Map<String, dynamic> toJson() => {
    ...data,
    if (isList) 'items': items,
    if (isPaged) ...{
      'page': page,
      'limit': limit,
      'total': total,
      'has_more': hasMore,
    },
  };

  static List<Map<String, dynamic>> _maps(Object? v) => v is List
      ? [
          for (final e in v)
            if (e is Map) Map<String, dynamic>.from(e),
        ]
      : const [];
}

class MyData {
  const MyData({required this.raw, required this.sections, this.exportedAt});

  factory MyData.fromJson(Map<String, dynamic> json) {
    final order = json['sections'];
    return MyData(
      raw: json,
      exportedAt: json['exported_at'] as String?,
      sections: [
        if (order is List)
          for (final key in order)
            if (key is String &&
                knownMyDataSections.contains(key) &&
                json[key] is Map)
              MyDataSection.fromJson(
                key,
                Map<String, dynamic>.from(json[key] as Map),
              ),
      ],
    );
  }

  /// The whole response, for sharing.
  final Map<String, dynamic> raw;

  /// RFC 3339.
  final String? exportedAt;

  /// The sections to show, in the server's order.
  final List<MyDataSection> sections;

  MyDataSection? section(String key) {
    for (final s in sections) {
      if (s.key == key) return s;
    }
    return null;
  }

  MyData withSection(MyDataSection section) => MyData(
    raw: raw,
    exportedAt: exportedAt,
    sections: [for (final s in sections) s.key == section.key ? section : s],
  );

  /// What the server sent, with the loaded pages in place of the first ones.
  Map<String, dynamic> toJson() => {
    ...raw,
    for (final s in sections) s.key: s.toJson(),
  };
}
