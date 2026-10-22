import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/ride_booking/domain/models/vehicle_estimation.dart';
import 'package:customer_app/features/ride_booking/presentation/controllers/booking_controller.dart';
import 'package:customer_app/features/ride_booking/presentation/states/booking_state.dart';
import 'package:customer_app/features/ride_booking/presentation/widgets/vehicle_selection_item.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VehicleSelectionSheet extends ConsumerWidget {
  // Provided by the parent DraggableScrollableSheet; the list scrolls with it,
  // so dragging the list resizes/snaps the sheet.
  final ScrollController scrollController;
  final List<VehicleEstimation> estimations;
  final Function(String id) onVehicleSelected;

  /// "ถัดไป": on to step 2 (payment, code, points, the request button).
  final VoidCallback onNext;

  /// Pickup or dropoff is still unset, so no estimate can be requested.
  final bool isMissingLocation;

  /// Opens the pickup/dropoff picker (shown when [isMissingLocation]).
  final VoidCallback? onPickLocation;

  /// Re-runs the fare estimate after it failed.
  final VoidCallback? onRetryEstimate;

  /// The pickup is outside every open service zone: the list says so (with a
  /// "pick another pickup" action) and the request button stays disabled.
  final bool outOfServiceArea;

  const VehicleSelectionSheet({
    super.key,
    required this.scrollController,
    required this.estimations,
    required this.onNext,
    required this.onVehicleSelected,
    this.isMissingLocation = false,
    this.onPickLocation,
    this.onRetryEstimate,
    this.outOfServiceArea = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingControllerProvider);
    final bookingState = bookingAsync.value ?? const BookingState();
    final notifier = ref.read(bookingControllerProvider.notifier);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;

    // No auto-select: the user must explicitly pick a vehicle before the
    // "request ride" button becomes enabled.
    final hasVehicleSelected = bookingState.vehicleTypeId != null;
    VehicleEstimation? selectedEstimation;
    for (final e in estimations) {
      if (e.vehicleTypeId == bookingState.vehicleTypeId) {
        selectedEstimation = e;
        break;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Grabber. Drag anywhere on the sheet/list to resize; the parent
          // DraggableScrollableSheet snaps to 1 row / 3 rows / almost full.
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.semanticGrayNeutralBgDarkgray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle list — fills the draggable sheet and scrolls with its
          // ScrollController, so dragging it drives the sheet's snap. The
          // loading/empty states are still scrollable so the drag keeps working.
          Expanded(
            child: outOfServiceArea
                ? ListView(
                    controller: scrollController,
                    children: [
                      SizedBox(
                        key: const Key('rideOutOfServiceArea'),
                        height: 160,
                        child: _EmptyEstimate(
                          message: l10n.errServiceAreaUnavailable,
                          actionLabel: l10n.choosePickupAction,
                          onAction: onPickLocation,
                        ),
                      ),
                    ],
                  )
                : bookingAsync.isLoading
                ? ListView(
                    controller: scrollController,
                    children: const [
                      SizedBox(
                        height: 160,
                        child: Center(child: MassLoadingM(size: 56)),
                      ),
                    ],
                  )
                : estimations.isEmpty
                ? ListView(
                    controller: scrollController,
                    children: [
                      SizedBox(
                        height: 160,
                        child: _EmptyEstimate(
                          // Without a pickup/dropoff no estimate is ever sent,
                          // and a failed one never retries on its own — so
                          // only say "calculating" while one can still land.
                          message: isMissingLocation
                              ? l10n.selectPickupFirst
                              : bookingAsync.hasError
                              ? l10n.fareEstimateFailed
                              : l10n.calculatingPrice,
                          actionLabel: isMissingLocation
                              ? l10n.choosePickupAction
                              : bookingAsync.hasError
                              ? l10n.retry
                              : null,
                          onAction: isMissingLocation
                              ? onPickLocation
                              : onRetryEstimate,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: estimations.length,
                    itemBuilder: (context, index) {
                      final estimation = estimations[index];
                      final isSelected =
                          bookingState.vehicleTypeId ==
                          estimation.vehicleTypeId;

                      return VehicleSelectionItem(
                        estimation: estimation,
                        isSelected: isSelected,
                        onTap: () {
                          notifier.setVehicleType(estimation.vehicleTypeId);
                        },
                        iconPath: notifier.getVehicleIcon(
                          estimation.vehicleTypeName,
                        ),
                      );
                    },
                  ),
          ),

          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.semanticGrayNeutralBorderLightgray,
          ),

          // "ถัดไป · ฿X" to step 2. Disabled until a vehicle is picked — and
          // the label says so, so the greyed-out state isn't a dead end.
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: bottomPadding > 0 ? bottomPadding : 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                key: const Key('rideNext'),
                onPressed: hasVehicleSelected && !outOfServiceArea
                    ? onNext
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.semanticDisabledBgLow,
                  disabledForegroundColor: AppColors.semanticDisabledFgOnGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  hasVehicleSelected && selectedEstimation != null
                      ? l10n.rideNext(fmtBaht(selectedEstimation.payable))
                      : l10n.selectVehicleFirst,
                  style: AppTypography.heading4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Placeholder for the vehicle list when there are no estimations yet, with
/// an optional action (pick a location / retry).
class _EmptyEstimate extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyEstimate({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, textAlign: TextAlign.center),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}
