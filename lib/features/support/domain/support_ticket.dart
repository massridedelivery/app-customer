/// A customer's report to the support team ("แจ้งปัญหา"), from
/// `/api/customer/support/tickets`.
library;

/// What the report is about. [api] is the value the backend stores.
enum SupportCategory {
  driverBehavior('driver_behavior'),
  safety('safety'),
  farePayment('fare_payment'),
  itemIssue('item_issue'),
  lostItem('lost_item'),
  appIssue('app_issue'),
  other('other');

  const SupportCategory(this.api);

  final String api;

  static SupportCategory fromApi(String? v) => SupportCategory.values
      .firstWhere((c) => c.api == v, orElse: () => SupportCategory.other);

  /// The topics offered for [service] (null = a report not tied to an order).
  static List<SupportCategory> forService(SupportService? service) =>
      switch (service) {
        SupportService.ride => const [
          driverBehavior,
          safety,
          farePayment,
          lostItem,
          appIssue,
          other,
        ],
        SupportService.food || SupportService.parcel => const [
          driverBehavior,
          itemIssue,
          farePayment,
          safety,
          appIssue,
          other,
        ],
        null => const [appIssue, farePayment, other],
      };
}

/// The order's service. [api] is the value the backend stores.
enum SupportService {
  ride('ride'),
  food('food'),
  parcel('parcel');

  const SupportService(this.api);

  final String api;

  static SupportService? fromApi(String? v) {
    for (final s in values) {
      if (s.api == v) return s;
    }
    return null;
  }
}

/// Where the customer filed it from. [api] is the value the backend stores.
enum SupportSource {
  tripDetail('trip_detail'),
  tracking('tracking'),
  profile('profile'),
  rating('rating');

  const SupportSource(this.api);

  final String api;
}

enum SupportStatus {
  open,
  inProgress,
  resolved,
  closed;

  static SupportStatus fromApi(String? v) => switch (v) {
    'in_progress' => inProgress,
    'resolved' => resolved,
    'closed' => closed,
    _ => open,
  };

  /// The customer can still add details.
  bool get isActive => this == open || this == inProgress;
}

class SupportAttachment {
  const SupportAttachment({required this.fileKey, this.url});

  final String fileKey;

  /// Presigned link to show the photo; null when the backend didn't sign one.
  final String? url;

  factory SupportAttachment.fromJson(Object? json) {
    if (json is String) return SupportAttachment(fileKey: json);
    final m = json is Map ? Map<String, dynamic>.from(json) : const {};
    final url = (m['url'] ?? m['view_url']) as String?;
    return SupportAttachment(
      fileKey: '${m['file_key'] ?? ''}',
      url: url == null || url.isEmpty ? null : url,
    );
  }
}

class SupportReply {
  const SupportReply({
    required this.id,
    required this.fromAdmin,
    required this.message,
    this.createdAt,
  });

  final String id;
  final bool fromAdmin;
  final String message;
  final DateTime? createdAt;

  factory SupportReply.fromJson(Map<String, dynamic> m) => SupportReply(
    id: '${m['id'] ?? ''}',
    fromAdmin: (m['from'] ?? m['sender']) != 'customer',
    message: '${m['message'] ?? ''}',
    createdAt: DateTime.tryParse('${m['created_at'] ?? ''}')?.toLocal(),
  );
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.category,
    required this.status,
    required this.description,
    this.ticketNo,
    this.service,
    this.refId,
    this.resolution,
    this.refundAmount,
    this.attachments = const [],
    this.replies = const [],
    this.unread = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? ticketNo;
  final SupportCategory category;
  final SupportService? service;
  final String? refId;
  final String description;
  final SupportStatus status;

  /// The team's closing note.
  final String? resolution;

  /// Money given back for this report, in baht.
  final double? refundAmount;
  final List<SupportAttachment> attachments;

  /// The conversation, oldest first (only on the detail endpoint).
  final List<SupportReply> replies;

  /// The team replied since the customer last opened it.
  final bool unread;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// "#T-…" when the backend numbers tickets, else the start of the id.
  String get displayNo => ticketNo?.isNotEmpty == true
      ? ticketNo!
      : (id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase());

  factory SupportTicket.fromJson(Map<String, dynamic> m) {
    String? str(Object? v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty ? null : s;
    }

    final refund = m['refund_amount'];
    final replies =
        [
          for (final r in (m['replies'] as List?) ?? const [])
            if (r is Map) SupportReply.fromJson(Map<String, dynamic>.from(r)),
        ]..sort(
          (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          ),
        );
    return SupportTicket(
      id: '${m['id'] ?? ''}',
      ticketNo: str(m['ticket_no']),
      category: SupportCategory.fromApi(str(m['category'])),
      service: SupportService.fromApi(str(m['service'])),
      refId: str(m['ref_id']),
      description: '${m['description'] ?? ''}',
      status: SupportStatus.fromApi(str(m['status'])),
      resolution: str(m['resolution']),
      refundAmount: refund is num
          ? refund.toDouble()
          : double.tryParse('${refund ?? ''}'),
      attachments: [
        for (final a in (m['attachments'] as List?) ?? const [])
          SupportAttachment.fromJson(a),
      ].where((a) => a.fileKey.isNotEmpty || a.url != null).toList(),
      replies: replies,
      unread: m['unread'] == true,
      createdAt: DateTime.tryParse('${m['created_at'] ?? ''}')?.toLocal(),
      updatedAt: DateTime.tryParse('${m['updated_at'] ?? ''}')?.toLocal(),
    );
  }
}

/// What the customer is filing.
class NewSupportTicket {
  const NewSupportTicket({
    required this.category,
    required this.description,
    required this.source,
    this.service,
    this.refId,
    this.attachments = const [],
    this.rating,
    this.tags = const [],
  });

  final SupportCategory category;
  final String description;
  final SupportSource source;
  final SupportService? service;
  final String? refId;

  /// `file_key`s of uploaded photos.
  final List<String> attachments;

  /// The stars and tags, when filed from a low rating.
  final int? rating;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
    'category': category.api,
    'description': description,
    'source': source.api,
    if (service != null) 'service': service!.api,
    if (refId != null && refId!.isNotEmpty) 'ref_id': refId,
    if (attachments.isNotEmpty) 'attachments': attachments,
    if (rating != null) 'rating': rating,
    if (tags.isNotEmpty) 'tags': tags,
  };
}
