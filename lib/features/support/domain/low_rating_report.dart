import 'package:customer_app/features/support/domain/support_ticket.dart';

/// Highest star rating that offers the "what went wrong" tags.
const int kLowRatingMax = 3;

/// The tags offered on a low ride rating and the report topic each points
/// to. Like the positive tags, the Thai text is what the backend receives.
const Map<String, SupportCategory> kLowRatingTags = {
  'ขับขี่อันตราย': SupportCategory.safety,
  'ไม่สุภาพ': SupportCategory.driverBehavior,
  'มาช้า': SupportCategory.driverBehavior,
  'เส้นทางอ้อม': SupportCategory.farePayment,
  'รถไม่สะอาด': SupportCategory.driverBehavior,
  'เก็บเงินเกิน': SupportCategory.farePayment,
};

/// The report filed for the team when a ride gets [rating] ≤ [kLowRatingMax]
/// stars with at least one of [kLowRatingTags]; null otherwise.
///
/// The topic is the most serious one picked: safety, then the rider's
/// behaviour, then the fare. [heading] gives "รายงานจากการให้คะแนน N ดาว",
/// [tagLabel] the tag's text in the app's language.
NewSupportTicket? lowRatingReport({
  required String jobId,
  required int rating,
  required Iterable<String> tags,
  required String comment,
  required String Function(int stars) heading,
  required String Function(String tag) tagLabel,
}) {
  if (rating < 1 || rating > kLowRatingMax) return null;
  final picked = tags.where(kLowRatingTags.containsKey).toList();
  if (picked.isEmpty) return null;
  final topics = picked.map((t) => kLowRatingTags[t]!).toSet();
  final category = topics.contains(SupportCategory.safety)
      ? SupportCategory.safety
      : topics.contains(SupportCategory.driverBehavior)
      ? SupportCategory.driverBehavior
      : SupportCategory.farePayment;
  final note = comment.trim();
  return NewSupportTicket(
    category: category,
    description: [
      '${heading(rating)}: ${picked.map(tagLabel).join(', ')}',
      if (note.isNotEmpty) note,
    ].join('\n'),
    source: SupportSource.rating,
    service: SupportService.ride,
    refId: jobId,
    rating: rating,
    tags: picked,
  );
}
