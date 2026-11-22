import 'dart:math' as math;

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/advance_booking/domain/advance_slots.dart';
import 'package:customer_app/features/advance_booking/presentation/advance_common.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/home/presentation/widgets/home_service_card.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Whether the home grid shows the "จองล่วงหน้า" card. A guest always sees it
/// (the router sends them to sign in). A signed-in customer sees it once
/// `GET /api/customer/advance-booking/config` has loaded, whatever `enabled`
/// says: a backend without advance booking (the route 404s) hides the card
/// rather than leading to an error page.
final homeAdvanceCardVisibleProvider = Provider.autoDispose<bool>((ref) {
  final signedIn = ref.watch(
    authControllerProvider.select((s) => s.isAuthenticated),
  );
  if (!signedIn) return true;
  return ref.watch(advanceConfigProvider).hasValue;
});

/// The home grid's 4th card, "จองล่วงหน้า" (HomeCard variant B): styled like
/// the other service cards, with a drawn 3D-style calendar where they have
/// their 3D image. While the admin has advance booking off, tapping it shows
/// their closed dialog instead of opening the flow.
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
    return HomeServiceCard(
      inkKey: const Key('homeAdvanceBookingCard'),
      title: l10n.advanceHomeCardTitle,
      subtitle: l10n.advanceHomeCardSubDefault,
      badge: l10n.advanceHomeCardBadge,
      badgeColor: AppColors.primary,
      art: AdvanceCalendarArt(day: AdvanceSlots.toBangkok(DateTime.now()).day),
      onTap: _open,
    );
  }
}

/// A small 3D-style calendar page showing [day], standing in for a 3D image
/// until one is made: white page tilted −8°, red header with two binder
/// rings, soft red shadow. Drawn at 76×80 and scaled to fit its box.
class AdvanceCalendarArt extends StatelessWidget {
  const AdvanceCalendarArt({super.key, required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Transform.rotate(
          angle: -8 * math.pi / 180,
          child: Container(
            width: 76,
            height: 80,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40B71130),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 24,
                  color: AppColors.primary,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_Ring(), _Ring()],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$day',
                      style: AppTypography.heading3.copyWith(
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1B1F),
                      ),
                    ),
                  ),
                ),
                // Light bottom edge, for depth.
                Container(height: 4, color: const Color(0xFFEBECEF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF8E0D25),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
