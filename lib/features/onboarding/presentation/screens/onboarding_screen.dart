import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:customer_app/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static final List<Map<String, dynamic>> _pages = [
    {
      'icon': const Icon(
        Icons.pan_tool_alt,
        size: 100,
        color: AppColors.primary,
      ),
      'title': 'เรียกรถ',
      'description': 'เรียกรถและรับการบริการจาก\nคนขับในชุมชนใกล้เคียง',
    },
    {
      'icon': const Icon(
        Icons.phone_android,
        size: 100,
        color: AppColors.primary,
      ),
      'title': 'ยืนยันคนขับของคุณ',
      'description':
          'เครือข่ายคนขับที่ครอบคลุมช่วยให้คุณ\nเดินทางได้อย่างสะดวก ปลอดภัย และประหยัด',
    },
    {
      'icon': const Icon(
        Icons.share_location_sharp,
        size: 100,
        color: AppColors.primary,
      ),
      'title': 'ติดตามการเดินทางของคุณ',
      'description':
          'ทราบข้อมูลคนขับล่วงหน้าและสามารถ\nดูตำแหน่งปัจจุบันแบบเรียลไทม์บนแผนที่',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPageIndex = ref.watch(onboardingControllerProvider);
    final pageController = PageController(initialPage: currentPageIndex);

    void onNextPressed() {
      if (currentPageIndex < _pages.length - 1) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        context.go('/location_setup');
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => ref
                    .read(onboardingControllerProvider.notifier)
                    .onPageChanged(index),
                itemBuilder: (context, index) {
                  final pageData = _pages[index];
                  return OnboardingPageWidget(
                    icon: pageData['icon'],
                    title: pageData['title'],
                    description: pageData['description'],
                  );
                },
              ),
            ),

            // Bottom Section (Button & Indicators)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 40.0,
              ),
              child: Column(
                children: [
                  if (currentPageIndex == _pages.length - 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'เริ่มต้นใช้งาน!',
                          style: AppTypography.label1.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 50),

                  const SizedBox(height: 30),

                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(
                        index: index,
                        currentPageIndex: currentPageIndex,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required int index, required int currentPageIndex}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 4,
      width: currentPageIndex == index ? 24 : 12,
      decoration: BoxDecoration(
        color: currentPageIndex == index
            ? AppColors.primary
            : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
