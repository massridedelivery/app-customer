import 'package:app_settings/app_settings.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/services/connectivity_monitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide network alert. Wraps the whole app (see [App.builder]) and floats a
/// thin strip at the very top when the connection is offline or weak:
/// - offline → red, with a "ไปที่ตั้งค่า" action that opens the device Wi-Fi /
///   mobile-data settings so the user can reconnect.
/// - weak/unstable → amber warning.
/// Mirrors the driver app's connectivity monitor.
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityMonitorProvider);

    return Stack(
      children: [
        child,
        if (status.isAlert)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _AlertStrip(status: status),
            ),
          ),
      ],
    );
  }
}

class _AlertStrip extends ConsumerWidget {
  final NetworkStatus status;

  const _AlertStrip({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = status.quality == NetworkQuality.offline;
    final color = offline ? AppColors.error : AppColors.foundationOrange600;
    final title = offline
        ? (status.hasCarrier
              ? 'เชื่อมต่ออินเทอร์เน็ตไม่ได้'
              : 'ไม่มีสัญญาณอินเทอร์เน็ต')
        : 'สัญญาณอินเทอร์เน็ตอ่อน / ไม่เสถียร';
    final subtitle = offline
        ? 'ตรวจสอบ Wi-Fi หรือเน็ตมือถือของคุณ'
        : 'การเชื่อมต่อช้า อาจใช้งานไม่ราบรื่น';

    return Material(
      color: color,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.network_check_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption5.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (offline)
              TextButton(
                onPressed: () =>
                    AppSettings.openAppSettings(type: AppSettingsType.wifi),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'ไปที่ตั้งค่า',
                  style: AppTypography.caption4.copyWith(color: Colors.white),
                ),
              ),
            IconButton(
              onPressed: () =>
                  ref.read(connectivityMonitorProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              iconSize: 20,
              tooltip: 'ตรวจสอบอีกครั้ง',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
