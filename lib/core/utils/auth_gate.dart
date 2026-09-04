import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Guest guard for account-based actions (booking a ride, sending a parcel,
/// checking out). Guests can browse freely (App Store 5.1.1), but the moment
/// they trigger an action that needs an account we send them to login.
///
/// Returns `true` when the user is authenticated (the caller proceeds).
/// Returns `false` for a guest — after routing to `/auth` — so the caller must
/// abort the action.
bool ensureLoggedIn(BuildContext context, WidgetRef ref) {
  if (ref.read(authControllerProvider).isAuthenticated) return true;
  context.push('/auth');
  return false;
}
