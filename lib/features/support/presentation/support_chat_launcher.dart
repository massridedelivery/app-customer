import 'package:customer_app/core/data/support_config_provider.dart';
import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/features/support/data/support_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The backend refuses support calls with these while admin has the feature
/// switched off.
const kSupportDisabledCodes = {
  'SUPPORT_TICKETS_DISABLED',
  'SUPPORT_CHAT_DISABLED',
};

/// When [e] says support was switched off, re-reads the switches so the app
/// hides what it no longer offers. Returns whether it was that.
bool handleSupportDisabled(WidgetRef ref, ApiError e) {
  if (!kSupportDisabledCodes.contains(e.code)) return false;
  ref.invalidate(supportConfigProvider);
  return true;
}

/// "แชทกับเจ้าหน้าที่": opens the customer's live chat with the team (the
/// backend reuses their open one or starts a new one).
Future<void> openSupportChat(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ticket = await ref.read(supportRepositoryProvider).startChat();
    if (!context.mounted) return;
    context.push('/support/tickets/${ticket.id}');
  } on ApiError catch (e) {
    handleSupportDisabled(ref, e);
    messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
  }
}
