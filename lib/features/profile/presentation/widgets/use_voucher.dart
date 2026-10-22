import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "ใช้เลย" on a voucher: opens the service it's for with the code ready in
/// the promo box. RIDE / MESSENGER pre-fill it; FOOD's checkout picks codes
/// from its own list, so the code is copied for pasting. ALL asks which.
Future<void> useVoucherCode(
  BuildContext context,
  WidgetRef ref, {
  required String code,
  required String appliesTo,
}) async {
  final l10n = AppLocalizations.of(context)!;
  var service = appliesTo.toUpperCase();
  if (service != 'RIDE' && service != 'FOOD' && service != 'MESSENGER') {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.vouchersChooseService,
                style: AppTypography.heading5,
              ),
            ),
            for (final (value, icon, label) in [
              ('RIDE', Icons.directions_car_outlined, l10n.serviceRide),
              ('FOOD', Icons.restaurant_rounded, l10n.serviceFood),
              ('MESSENGER', Icons.inventory_2_outlined, l10n.serviceMessenger),
            ])
              ListTile(
                key: Key('voucherService-$value'),
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.of(context).pop(value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    service = picked;
  }

  switch (service) {
    case 'RIDE':
      ref.read(pendingPromoCodeProvider.notifier).set(code, 'RIDE');
      context.push('/ride-landing');
    case 'MESSENGER':
      ref.read(pendingPromoCodeProvider.notifier).set(code, 'MESSENGER');
      context.push('/messenger-booking');
    default:
      await Clipboard.setData(ClipboardData(text: code));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.vouchersCodeCopiedHint)));
      context.push('/food-delivery');
  }
}
