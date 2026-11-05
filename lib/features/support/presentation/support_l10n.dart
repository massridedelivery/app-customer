import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

extension SupportCategoryText on SupportCategory {
  String label(AppLocalizations l10n) => switch (this) {
    SupportCategory.driverBehavior => l10n.supportCatDriverBehavior,
    SupportCategory.safety => l10n.supportCatSafety,
    SupportCategory.farePayment => l10n.supportCatFarePayment,
    SupportCategory.itemIssue => l10n.supportCatItemIssue,
    SupportCategory.lostItem => l10n.supportCatLostItem,
    SupportCategory.appIssue => l10n.supportCatAppIssue,
    SupportCategory.other => l10n.supportCatOther,
  };

  IconData get icon => switch (this) {
    SupportCategory.driverBehavior => Icons.person_off_outlined,
    SupportCategory.safety => Icons.health_and_safety_outlined,
    SupportCategory.farePayment => Icons.receipt_long_outlined,
    SupportCategory.itemIssue => Icons.inventory_2_outlined,
    SupportCategory.lostItem => Icons.backpack_outlined,
    SupportCategory.appIssue => Icons.phone_iphone_outlined,
    SupportCategory.other => Icons.more_horiz_rounded,
  };
}

extension SupportServiceText on SupportService {
  String label(AppLocalizations l10n) => switch (this) {
    SupportService.ride => l10n.supportServiceRide,
    SupportService.food => l10n.supportServiceFood,
    SupportService.parcel => l10n.supportServiceParcel,
  };

  IconData get icon => switch (this) {
    SupportService.ride => Icons.two_wheeler_rounded,
    SupportService.food => Icons.restaurant_rounded,
    SupportService.parcel => Icons.inventory_2_rounded,
  };
}

extension SupportStatusText on SupportStatus {
  String label(AppLocalizations l10n) => switch (this) {
    SupportStatus.open => l10n.supportStatusOpen,
    SupportStatus.inProgress => l10n.supportStatusInProgress,
    SupportStatus.resolved => l10n.supportStatusResolved,
    SupportStatus.closed => l10n.supportStatusClosed,
  };

  /// (text, background) for the status pill.
  (Color, Color) get colors => switch (this) {
    SupportStatus.open => (
      AppColors.semanticSupportOrangeFgOnLow,
      AppColors.semanticSupportOrangeBgLow,
    ),
    SupportStatus.inProgress => (
      AppColors.semanticSupportBlueFgOnLow,
      AppColors.semanticSupportBlueBgLow,
    ),
    SupportStatus.resolved => (
      AppColors.semanticSupportMintFgOnLow,
      AppColors.semanticSupportMintBgLow,
    ),
    SupportStatus.closed => (
      AppColors.semanticSupportGrayFgOnLow,
      AppColors.semanticSupportGrayBgLow,
    ),
  };
}

/// "รอดำเนินการ"-style pill.
class SupportStatusPill extends StatelessWidget {
  const SupportStatusPill(this.status, {super.key});

  final SupportStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (fg, bg) = status.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label(l10n),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
