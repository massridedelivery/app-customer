import 'package:customer_app/features/support/data/support_repository.dart';
import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The customer's reports, newest first ("ประวัติการแจ้งปัญหา").
final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>(
  (ref) => ref.watch(supportRepositoryProvider).list(),
);

/// One report with the team's replies. Opening it marks the replies read on
/// the backend.
final supportTicketProvider = FutureProvider.autoDispose
    .family<SupportTicket, String>(
      (ref, id) => ref.watch(supportRepositoryProvider).get(id),
    );
