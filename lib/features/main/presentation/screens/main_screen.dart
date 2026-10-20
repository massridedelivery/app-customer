import 'dart:async';
import 'dart:io' show Platform;

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/widgets/coach_marks.dart';
import 'package:customer_app/features/home/presentation/screens/service_selection_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:customer_app/features/trips/presentation/screens/trips_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/active_orders/presentation/controllers/active_orders_controller.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final HistoryStatus? initialHistoryStatus;
  const MainScreen({super.key, this.initialTab = 0, this.initialHistoryStatus});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex;
  late List<Widget> _screens;

  // Coach-mark targets. Owned here (not static) so two MainScreens during a
  // route transition never share a GlobalKey.
  final _locationKey = GlobalKey(debugLabel: 'coachLocation');
  final _servicesKey = GlobalKey(debugLabel: 'coachServices');
  final _ordersTabKey = GlobalKey(debugLabel: 'coachOrdersTab');

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _screens = [
      ServiceSelectionScreen(
        locationKey: _locationKey,
        servicesKey: _servicesKey,
      ),
      TripsScreen(initialStatus: widget.initialHistoryStatus),
      const ProfileScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleCoachMarks();
  }

  bool _coachScheduled = false;
  Timer? _coachTimer;

  /// First visit to home: a 3-step spotlight tour. Lets the home settle, then
  /// waits — however long — for a clear screen: no dialog or page on top
  /// (e.g. the turn-on-location popup) and the home tab showing.
  void _scheduleCoachMarks() {
    if (_coachScheduled) return;
    _coachScheduled = true;
    if (ref.read(appStorageProvider).hasSeenHomeCoachMarks) return;
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _coachTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
        if (!mounted) return t.cancel();
        final onTop = ModalRoute.of(context)?.isCurrent ?? false;
        if (onTop && _currentIndex == 0) {
          t.cancel();
          _showCoachMarks();
        }
      });
    });
  }

  @override
  void dispose() {
    _coachTimer?.cancel();
    super.dispose();
  }

  void _showCoachMarks() {
    final l10n = AppLocalizations.of(context)!;
    showCoachMarks(
      context,
      steps: [
        CoachMarkStep(
          target: _locationKey,
          title: l10n.coachLocationTitle,
          body: l10n.coachLocationBody,
        ),
        CoachMarkStep(
          target: _servicesKey,
          title: l10n.coachServicesTitle,
          body: l10n.coachServicesBody,
        ),
        CoachMarkStep(
          target: _ordersTabKey,
          title: l10n.coachOrdersTitle,
          body: l10n.coachOrdersBody,
        ),
      ],
      skipLabel: l10n.coachSkip,
      nextLabel: l10n.coachNext,
      doneLabel: l10n.coachDone,
      onFinish: () =>
          ref.read(appStorageProvider).setHasSeenHomeCoachMarks(true),
    );
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _currentIndex = widget.initialTab;
    }
    if (oldWidget.initialHistoryStatus != widget.initialHistoryStatus) {
      setState(() {
        _screens[1] = TripsScreen(initialStatus: widget.initialHistoryStatus);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // `extendBody: true` draws the body behind the system navigation area.
    // Android's system nav (esp. 3-button) is opaque, so lift the floating bar
    // above it by the device inset. iOS only has a thin home indicator — adding
    // that inset floats the bar too high, so there we hug the bottom with just
    // the base gap.
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    const baseGap = 24.0;
    final navBottom = Platform.isAndroid ? baseGap + bottomInset : baseGap;
    return Scaffold(
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          _screens[_currentIndex],

          // Floating Bottom Navigation
          Positioned(
            bottom: navBottom,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                height: 64, // Reduced height to match h-16
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Background Layer — a near-opaque frosted pill.
                    // Previously a live BackdropFilter blur (sigma 24), but the
                    // 0.8-opacity fill on top already hid almost all of it, so
                    // the blur re-rendered every frame content scrolled behind
                    // it for no visible gain — real jank on low-end devices.
                    // Dropping to a solid ~0.94 fill looks the same and is free.
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCF9F8).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),

                    // 2. Interactive Icons Layer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFloatingNavItem(
                          0,
                          Icons.home_outlined,
                          Icons.home_rounded,
                          AppLocalizations.of(context)!.navHome,
                        ),
                        _buildFloatingNavItem(
                          1,
                          Icons.feed_outlined,
                          Icons.feed_rounded,
                          AppLocalizations.of(context)!.navOrder,
                        ),
                        _buildFloatingNavItem(
                          2,
                          Icons.account_circle_outlined,
                          Icons.account_circle,
                          AppLocalizations.of(context)!.navAccount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return Expanded(
      // The orders tab is a coach-mark target.
      key: index == 1 ? _ordersTabKey : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Guests may open every tab; the account tabs (ประวัติ/โปรไฟล์) render
          // an inline LoginRequiredView instead of their content.
          setState(() => _currentIndex = index);
          if (index == 0) {
            ref.read(activeOrdersControllerProvider.notifier).refresh();
          }
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Floating Circle for Selected Tab (Now truly outside)
            if (isSelected)
              Positioned(
                top: -8, // More aggressive offset to match example
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accentRedDeep, AppColors.primary],
                    ),
                    shape: BoxShape.circle,
                    // White border that creates the "cutout" look against background
                    border: Border.all(
                      color: const Color(0xFFFCF9F8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(filledIcon, color: Colors.white, size: 24),
                ),
              ),

            // Icon and Label Container
            SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isSelected) ...[
                    Icon(outlineIcon, color: const Color(0xFF64748B), size: 24),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: AppTypography.caption5.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ] else ...[
                    // When selected, push the label to the bottom to make room for the bubble
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: AppTypography.caption4.copyWith(
                            color: const Color(0xFF00236F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
