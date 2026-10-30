import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/update/force_update.dart';
import 'package:customer_app/core/update/force_update_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Offers the pending [suggestUpdateProvider] update, if any, as a dialog the
/// user can dismiss ("ไว้ทีหลัง"). Called by the main screen when it opens and
/// whenever a check finds one. Another dialog on top leaves it for the next
/// launch rather than stacking.
Future<void> offerUpdateSuggestion(BuildContext context, WidgetRef ref) async {
  final update = ref.read(suggestUpdateProvider);
  if (update == null || !context.mounted) return;
  if (ModalRoute.of(context)?.isCurrent == false) return;
  await ref.read(suggestUpdateProvider.notifier).shown();
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final note = update.note(Localizations.localeOf(context).languageCode);
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('updateSuggestion'),
      icon: const Icon(
        Icons.system_update_rounded,
        color: AppColors.primary,
        size: 36,
      ),
      title: Text(
        l10n.forceUpdateTitle,
        textAlign: TextAlign.center,
        style: AppTypography.heading4,
      ),
      content: Text(
        note ?? l10n.updateSuggestBody,
        textAlign: TextAlign.center,
        style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          key: const Key('updateSuggestionLater'),
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            textStyle: AppTypography.label2,
          ),
          child: Text(l10n.updateSuggestLater),
        ),
        FilledButton(
          key: const Key('updateSuggestionUpdate'),
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            textStyle: AppTypography.label2,
          ),
          child: Text(l10n.updateSuggestUpdate),
        ),
      ],
    ),
  );
  if (go == true) await openAppUpdate(update);
}
