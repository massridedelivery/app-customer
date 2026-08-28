import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/data/repositories/service_area_repository.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shown when the customer's current zone isn't open for a service yet
/// (SCRUM zone-availability). Reached from the ride flow when the backend
/// reports `available:false` for the current location. Styled to the app; no
/// "register / waitlist" action — customers are already signed up.
class ServiceUnavailableScreen extends ConsumerStatefulWidget {
  /// Human-readable area for the current location (e.g. "นนทบุรี").
  final String areaName;

  /// Coordinates used for the re-check, when available.
  final double? lat;
  final double? lng;

  /// Service being gated — shown in the title ("เรียกรถ").
  final String serviceLabel;

  const ServiceUnavailableScreen({
    super.key,
    this.areaName = '',
    this.lat,
    this.lng,
    this.serviceLabel = 'เรียกรถ',
  });

  @override
  ConsumerState<ServiceUnavailableScreen> createState() =>
      _ServiceUnavailableScreenState();
}

class _ServiceUnavailableScreenState
    extends ConsumerState<ServiceUnavailableScreen> {
  late String _areaName = widget.areaName;
  bool _checking = false;

  String get _areaLabel => _areaName.isNotEmpty ? _areaName : 'พื้นที่ของคุณ';

  Future<void> _recheck() async {
    if (_checking) return;
    // Prefer the freshest location; fall back to whatever was passed in.
    final loc = ref.read(homeControllerProvider).currentLocation;
    final lat = loc?.latitude ?? widget.lat;
    final lng = loc?.longitude ?? widget.lng;
    if (lat == null || lng == null) {
      _snack('ไม่พบตำแหน่งปัจจุบัน กรุณาเปิด GPS แล้วลองใหม่');
      return;
    }
    setState(() => _checking = true);
    final result = await ref
        .read(serviceAreaRepositoryProvider)
        .check(lat: lat, lng: lng);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (result.areaName.isNotEmpty) _areaName = result.areaName;
    });
    if (result.available) {
      context.go('/ride-landing');
    } else {
      _snack('บริการยังไม่เปิดใน$_areaLabel');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/main'),
        ),
        title: Text(
          widget.serviceLabel,
          style: AppTypography.heading5.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wrong_location_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'เร็วๆ นี้ในพื้นที่ของคุณ',
                textAlign: TextAlign.center,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ขณะนี้ยังไม่เปิดให้บริการใน$_areaLabel',
                textAlign: TextAlign.center,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ทีมงานกำลังขยายพื้นที่ให้บริการ อีกไม่นานเราจะเปิดให้บริการในพื้นที่ของคุณ',
                textAlign: TextAlign.center,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Current location chip.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.foundationGrayscale100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ตำแหน่งของคุณ: $_areaLabel',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              // Re-check.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : _recheck,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh_rounded,
                          size: 20, color: AppColors.primary),
                  label: Text(
                    _checking ? 'กำลังตรวจสอบ...' : 'ตรวจสอบอีกครั้ง',
                    style: AppTypography.label1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back home.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/main'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'กลับหน้าหลัก',
                    style: AppTypography.label1.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
