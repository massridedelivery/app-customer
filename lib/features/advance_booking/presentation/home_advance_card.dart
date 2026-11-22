import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The home grid's 4th card, "จองล่วงหน้า" (Main variant A). Always shown:
/// while the admin has advance booking off, tapping it shows their closed
/// dialog instead of opening the flow. A guest is sent to sign in by the
/// router (the flow needs an account).
class HomeAdvanceBookingCard extends ConsumerStatefulWidget {
  const HomeAdvanceBookingCard({super.key});

  @override
  ConsumerState<HomeAdvanceBookingCard> createState() =>
      _HomeAdvanceBookingCardState();
}

class _HomeAdvanceBookingCardState
    extends ConsumerState<HomeAdvanceBookingCard> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    final signedIn = ref.read(authControllerProvider).isAuthenticated;
    if (!signedIn) {
      context.push('/advance-booking');
      return;
    }
    _opening = true;
    try {
      ref.invalidate(advanceConfigProvider);
      final config = await ref.read(advanceConfigProvider.future);
      if (!mounted) return;
      if (!config.enabled) {
        await showAdvanceClosedDialog(
          context,
          title: config.closedTitle,
          message: config.closedMessage,
        );
        return;
      }
      context.push('/advance-booking');
    } catch (_) {
      // Config unreachable: open the flow, which shows a retry.
      if (mounted) context.push('/advance-booking');
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    final config = signedIn ? ref.watch(advanceConfigProvider).value : null;
    final sub = config != null && config.enabled && config.maxDays > 0
        ? l10n.advanceHomeCardSub('${config.maxDays}')
        : l10n.advanceHomeCardSubDefault;
    return Material(
      color: AppColors.softRedBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      child: InkWell(
        key: const Key('homeAdvanceBookingCard'),
        borderRadius: BorderRadius.circular(16),
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.edit_calendar_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const Spacer(),
              Text(
                l10n.advanceHomeCardTitle,
                style: AppTypography.label1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.secondaryRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
