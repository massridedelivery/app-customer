import 'dart:async';

import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:customer_app/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First-run walkthrough: ride → parcels → safety → ready. No skip — four
/// short pages — and the last one asks for location before landing on home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Owned once and disposed — not rebuilt on every provider change.
  final PageController _pageController = PageController();
  bool _finishing = false;

  static const _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onNext(int current) async {
    if (current < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    if (_finishing) return;
    setState(() => _finishing = true);
    await _askForLocation();
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    // Land on the home as a guest — non-account features are browsable
    // without login (App Store 5.1.1); login is prompted at account actions.
    if (mounted) context.go('/main');
  }

  /// Starts the keep-alive HomeController — its location bootstrap shows the
  /// system permission dialog — and waits for the answer. Asked of everyone,
  /// but never blocks: a denial still lands on home (App Store 5.1.1), where
  /// the location hint can fix it later. The splash leaves this to us on the
  /// first run so the dialog comes after the explanation, not before.
  Future<void> _askForLocation() async {
    final answered = Completer<void>();
    final sub = ref.listenManual<LocationAccess>(
      homeControllerProvider.select((s) => s.locationAccess),
      (_, access) {
        if (access != LocationAccess.unknown && !answered.isCompleted) {
          answered.complete();
        }
      },
      fireImmediately: true,
    );
    try {
      await answered.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {},
      );
    } finally {
      sub.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(onboardingControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    // The ready page's coupon comes from the live promo list (guest-safe:
    // /api/public/promos) — no promo, no coupon.
    final promos = ref
        .watch(promoListProvider)
        .maybeWhen(
          data: (raw) => raw.whereType<Map<String, dynamic>>().toList(),
          orElse: () => const <Map<String, dynamic>>[],
        );
    final rideBadge = serviceBadgeOf(promos, 'ride', l10n);

    final pages = [
      (
        hero: const _PhotoHero(AppAssets.expRides),
        title: l10n.onboardRideTitle,
        description: l10n.onboardRideDesc,
      ),
      (
        hero: const _IconHero(AppAssets.ic3dMessenger),
        title: l10n.onboardParcelTitle,
        description: l10n.onboardParcelDesc,
      ),
      (
        hero: const _PhotoHero(AppAssets.expSafety),
        title: l10n.onboardTrackTitle,
        description: l10n.onboardTrackDesc,
      ),
      (
        hero: _PhotoHero(
          AppAssets.expFare,
          badge: rideBadge == null
              ? null
              : _PromoChip(text: rideBadge.text, caption: l10n.onboardPromoSub),
        ),
        title: l10n.onboardReadyTitle,
        description: l10n.onboardReadyDesc,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons over the photo / red heroes.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => ref
                    .read(onboardingControllerProvider.notifier)
                    .onPageChanged(index),
                itemBuilder: (context, index) => OnboardingPageWidget(
                  hero: pages[index].hero,
                  title: pages[index].title,
                  description: pages[index].description,
                  index: index,
                  count: pages.length,
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('onboardingNext'),
                  onPressed: _finishing ? null : () => _onNext(current),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: _finishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          // The last page leads into the OS location dialog.
                          // Apple rejects an "Allow" button in front of it, so
                          // it reads "เริ่มต้นใช้งาน" rather than "อนุญาต…".
                          current == _pageCount - 1
                              ? l10n.onboardGetStarted
                              : l10n.onboardNext,
                          style: AppTypography.label1.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoHero extends StatelessWidget {
  final String asset;
  final Widget? badge;

  const _PhotoHero(this.asset, {this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover),
        if (badge != null) Positioned(left: 20, bottom: 64, child: badge!),
      ],
    );
  }
}

class _IconHero extends StatelessWidget {
  final String asset;

  const _IconHero(this.asset);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Center(child: Image.asset(asset, width: 220, height: 220)),
      ),
    );
  }
}

class _PromoChip extends StatelessWidget {
  final String text;
  final String caption;

  const _PromoChip({required this.text, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: AppTypography.heading4.copyWith(
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
              Text(
                caption,
                style: AppTypography.body2.copyWith(
                  fontSize: 12,
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
