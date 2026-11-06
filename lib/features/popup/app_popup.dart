import 'dart:convert';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/core/update/force_update.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// What tapping a pop-up opens.
class AppPopupAction {
  const AppPopupAction({
    required this.type,
    required this.value,
    this.buttonText,
  });

  /// deeplink | url.
  final String type;
  final String value;

  /// Shown as a button under the image when set.
  final String? buttonText;

  static AppPopupAction? fromJson(Object? json) {
    if (json is! Map) return null;
    final value = '${json['value'] ?? ''}'.trim();
    if (value.isEmpty) return null;
    final text = '${json['button_text'] ?? ''}'.trim();
    return AppPopupAction(
      type: '${json['type'] ?? 'deeplink'}'.toLowerCase(),
      value: value,
      buttonText: text.isEmpty ? null : text,
    );
  }
}

/// One launch pop-up from `GET /api/customer/popups/active`. A new or
/// edited pop-up has a different [id] or [version], so it shows again.
class AppPopup {
  const AppPopup({
    required this.id,
    required this.version,
    required this.imageUrl,
    this.action,
  });

  final String id;
  final String version;
  final String imageUrl;
  final AppPopupAction? action;

  String get sessionKey => '$id:$version';

  static AppPopup? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = '${json['id'] ?? ''}'.trim();
    final image = '${json['image_url'] ?? ''}'.trim();
    if (id.isEmpty || image.isEmpty) return null;
    return AppPopup(
      id: id,
      version: '${json['version'] ?? ''}',
      imageUrl: image,
      action: AppPopupAction.fromJson(json['action']),
    );
  }
}

final appPopupRepositoryProvider = Provider<AppPopupRepository>(
  (ref) => AppPopupRepository(ref.watch(apiServiceProvider)),
);

class AppPopupRepository {
  AppPopupRepository(this._api);

  final ApiService _api;

  /// `GET /api/customer/popups/active` (no token needed). Any error: none.
  Future<List<AppPopup>> active() async {
    try {
      final res = await _api.dio.get('/api/customer/popups/active');
      final data = res.data;
      final items = data is Map ? data['items'] : null;
      return [
        if (items is List)
          for (final i in items) ?AppPopup.fromJson(i),
      ];
    } catch (e) {
      debugPrint('Popup: none ($e)');
      return const [];
    }
  }
}

/// Which pop-ups are suppressed: the device's "don't show again" map
/// (`app_popup_dismissed` = {id: version}) and the ones closed this session.
class AppPopupStore {
  AppPopupStore(this._prefs);

  final SharedPreferences _prefs;
  static const prefsKey = 'app_popup_dismissed';

  final Set<String> _closedThisSession = {};

  /// One pop-up per app open (cold start or return to the foreground).
  bool shownThisOpen = false;

  Map<String, String> get _dismissed {
    try {
      final raw = _prefs.getString(prefsKey);
      if (raw == null) return {};
      final m = jsonDecode(raw);
      return m is Map
          ? m.map((k, v) => MapEntry('$k', '$v'))
          : <String, String>{};
    } catch (_) {
      return {};
    }
  }

  bool isSuppressed(AppPopup p) =>
      _dismissed[p.id] == p.version ||
      _closedThisSession.contains(p.sessionKey);

  /// ✕ (or the backdrop / back, or opening it): gone for this session, and
  /// for good on this device when [dontShowAgain] was ticked.
  Future<void> close(AppPopup p, {required bool dontShowAgain}) async {
    _closedThisSession.add(p.sessionKey);
    if (!dontShowAgain) return;
    final m = _dismissed..[p.id] = p.version;
    await _prefs.setString(prefsKey, jsonEncode(m));
  }

  AppPopup? firstToShow(List<AppPopup> items) {
    for (final p in items) {
      if (!isSuppressed(p)) return p;
    }
    return null;
  }
}

final appPopupStoreProvider = Provider<AppPopupStore>(
  (ref) => AppPopupStore(ref.watch(sharedPreferencesProvider)),
);

bool _checking = false;

/// Loads the image before the pop-up opens; false when it won't load (then
/// no pop-up). Replaceable in tests.
@visibleForTesting
Future<bool> Function(String url, BuildContext context) appPopupPrecache =
    (url, context) async {
      var ok = true;
      await precacheImage(
        NetworkImage(url),
        context,
        onError: (_, _) => ok = false,
      );
      return ok;
    };

/// Shows the first launch pop-up that isn't suppressed, at most one per app
/// open, once home is on screen with nothing on top. Never blocks anything:
/// any error, or an image that won't load, means no pop-up.
Future<void> maybeShowAppPopup(BuildContext context, WidgetRef ref) async {
  final store = ref.read(appPopupStoreProvider);
  if (_checking || store.shownThisOpen) return;
  if (ref.read(forceUpdateProvider) != null) return;
  _checking = true;
  final AppPopup? popup;
  try {
    final items = await ref.read(appPopupRepositoryProvider).active();
    final first = store.firstToShow(items);
    if (first == null || !context.mounted) return;
    final loaded = await appPopupPrecache(first.imageUrl, context);
    if (!loaded || !context.mounted) return;
    // Something else is on screen (a page, a dialog): not now.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    popup = first;
    store.shownThisOpen = true;
  } finally {
    // Done checking; the dialog itself is guarded by [shownThisOpen].
    _checking = false;
  }
  await _show(context, ref, popup);
}

Future<void> _show(BuildContext context, WidgetRef ref, AppPopup popup) async {
  var dontShowAgain = false;
  final open = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AppPopupDialog(
        popup: popup,
        dontShowAgain: dontShowAgain,
        onDontShowAgain: (v) => setState(() => dontShowAgain = v),
        onClose: () => Navigator.of(dialogContext).pop(false),
        onOpen: () => Navigator.of(dialogContext).pop(true),
      ),
    ),
  );
  // ✕, the backdrop and Android back all count as ✕.
  await ref
      .read(appPopupStoreProvider)
      .close(popup, dontShowAgain: dontShowAgain);
  final action = popup.action;
  if (open != true || action == null || !context.mounted) return;
  if (action.type == 'url') {
    final uri = Uri.tryParse(action.value);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return;
  }
  // An unknown deeplink opens home (the router sends what it can't match
  // to /main).
  GoRouter.of(
    context,
  ).go(action.value.startsWith('/') ? action.value : '/main');
}

/// The pop-up card: the image, ✕, an optional button, and "ไม่แสดงหน้านี้
/// ในครั้งถัดไป".
class AppPopupDialog extends StatelessWidget {
  const AppPopupDialog({
    super.key,
    required this.popup,
    required this.dontShowAgain,
    required this.onDontShowAgain,
    required this.onClose,
    required this.onOpen,
  });

  final AppPopup popup;
  final bool dontShowAgain;
  final ValueChanged<bool> onDontShowAgain;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = popup.action;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The ✕ is a tab cut flush into the image's top-right corner,
          // clipped with the image so it follows its rounded corner.
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                GestureDetector(
                  key: const Key('appPopupImage'),
                  onTap: action == null ? null : onOpen,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                    ),
                    child: Image.network(
                      popup.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 280,
                        height: 280,
                        child: ColoredBox(color: AppColors.white),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                    child: InkWell(
                      key: const Key('appPopupClose'),
                      onTap: onClose,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.close, size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (action?.buttonText != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('appPopupButton'),
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  action!.buttonText!,
                  style: AppTypography.label1.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            key: const Key('appPopupDontShow'),
            onTap: () => onDontShowAgain(!dontShowAgain),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: dontShowAgain,
                  onChanged: (v) => onDontShowAgain(v ?? false),
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  activeColor: AppColors.primary,
                ),
                Text(
                  l10n.popupDontShowAgain,
                  style: AppTypography.body3.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
