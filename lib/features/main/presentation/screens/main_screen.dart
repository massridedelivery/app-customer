import 'dart:ui';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _screens = [
      const ServiceSelectionScreen(),
      TripsScreen(initialStatus: widget.initialHistoryStatus),
      const ProfileScreen(),
    ];
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
    return Scaffold(
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          _screens[_currentIndex],

          // Floating Bottom Navigation
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                height: 64, // Reduced height to match h-16
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Background Layer (Blurred & Glass)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFCF9F8,
                            ).withValues(alpha: 0.8),
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
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
