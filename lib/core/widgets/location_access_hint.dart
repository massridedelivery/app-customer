import 'package:app_settings/app_settings.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline prompt shown under a pickup field when the app can't use the device
/// location (permission denied, location services off, or the fix failed).
///
/// Lets the user fix it in place: ask for permission again, or — when it was
/// permanently denied — jump to the app's system Settings, re-checking when the
/// app comes back to the foreground. Renders nothing while location is still
/// resolving, once it's available, or when a pickup was chosen manually.
class LocationAccessHint extends ConsumerStatefulWidget {
  const LocationAccessHint({super.key});

  @override
  ConsumerState<LocationAccessHint> createState() => _LocationAccessHintState();
}

class _LocationAccessHintState extends ConsumerState<LocationAccessHint> {
  late final AppLifecycleListener _lifecycle;

  /// Set when we send the user to system Settings, so returning to the app
  /// re-checks location. Re-checking on every resume would re-show the
  /// permission prompt each time the app is foregrounded.
  bool _sentToSettings = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (!_sentToSettings) return;
        _sentToSettings = false;
        ref.read(homeControllerProvider.notifier).retryLocation();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _fix(LocationAccess access) async {
    if (access == LocationAccess.deniedForever) {
      _sentToSettings = true;
      await AppSettings.openAppSettings();
      return;
    }
    // Asking again shows the system permission / "turn on location" dialog.
    await ref.read(homeControllerProvider.notifier).retryLocation();
    if (!mounted) return;
    final after = ref.read(homeControllerProvider).locationAccess;
    if (after == LocationAccess.deniedForever) {
      _sentToSettings = true;
      await AppSettings.openAppSettings();
    } else if (after == LocationAccess.serviceDisabled) {
      // iOS can't switch location services on from an in-app dialog.
      _sentToSettings = true;
      await AppSettings.openAppSettings(type: AppSettingsType.location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(
      homeControllerProvider.select((s) => s.locationAccess),
    );
    final hasPickup = ref.watch(
      homeControllerProvider.select((s) => s.pickupLocation != null),
    );
    if (hasPickup ||
        access == LocationAccess.unknown ||
        access == LocationAccess.granted) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final message = switch (access) {
      LocationAccess.serviceDisabled => l10n.locationServiceOffHint,
      LocationAccess.unavailable => l10n.locationUnavailableHint,
      _ => l10n.locationPermissionHint,
    };
    final action = switch (access) {
      LocationAccess.deniedForever => l10n.settings,
      LocationAccess.unavailable => l10n.retry,
      _ => l10n.allowLocation,
    };

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.foundationRed100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 18,
            color: AppColors.foundationRed700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption5.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _fix(access),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.foundationRed700,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              action,
              style: AppTypography.label2.copyWith(
                color: AppColors.foundationRed700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
