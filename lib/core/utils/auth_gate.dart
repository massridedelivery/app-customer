import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Guest guard for account-based *actions* (booking a ride, sending a parcel).
/// Guests browse freely (App Store 5.1.1); when they trigger an action that
/// needs an account, send them to login. Account *screens* (Profile, History)
/// instead render an inline [LoginRequiredView] in place of their content.
///
/// Returns `true` when authenticated (caller proceeds); `false` for a guest —
/// after routing to `/auth` — so the caller aborts the action.
bool ensureLoggedIn(BuildContext context, WidgetRef ref) {
  if (ref.read(authControllerProvider).isAuthenticated) return true;
  context.push('/auth');
  return false;
}
