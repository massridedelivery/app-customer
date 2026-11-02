import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/profile/data/datasources/account_remote_data_source.dart';
import 'package:customer_app/features/profile/domain/models/my_data.dart';
import 'package:customer_app/features/profile/presentation/controllers/my_data_controller.dart';
import 'package:customer_app/features/profile/presentation/widgets/loyalty_format.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// "ข้อมูลของฉัน": everything the platform holds about the customer, read
/// only (PDPA right of access). Edits go through the existing screens, linked
/// from each section. Opened from Profile → ความเป็นส่วนตัว.
class MyDataScreen extends ConsumerWidget {
  const MyDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(myDataControllerProvider);

    ref.listen(myDataControllerProvider, (_, next) {
      if (next.error is DataExportAccountGone) _accountGone(context, ref);
    });

    final data = async.value;
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        title: Text(l10n.myDataTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (data != null && !async.isLoading)
            IconButton(
              key: const Key('myDataShare'),
              tooltip: l10n.myDataShare,
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _share(context, data),
            ),
        ],
      ),
      body: async.isLoading
          ? const Center(child: MassLoadingM(size: 48))
          : async.hasError
          ? _ErrorView(
              error: async.error,
              onRetry: () =>
                  ref.read(myDataControllerProvider.notifier).retry(),
            )
          : _Body(data: data!),
    );
  }

  /// The user's own copy, through the system share sheet (data portability).
  static void _share(BuildContext context, MyData data) {
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: const JsonEncoder.withIndent('  ').convert(data.toJson()),
        subject: AppLocalizations.of(context)!.myDataShareSubject,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  static Future<void> _accountGone(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.myDataAccountGone, style: AppTypography.body1),
        actions: [
          TextButton(
            key: const Key('myDataAccountGoneOk'),
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.myDataAccountGoneOk),
          ),
        ],
      ),
    );
    // Signing out sends the router back to the guest home.
    if (context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});
  final MyData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = data.section('profile');
    return ListView(
      key: const Key('myDataList'),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (profile != null) ...[
          _Header(profile: profile.data),
          const SizedBox(height: 16),
        ],
        for (final s in data.sections) ...[
          _SectionCard(
            section: s,
            onLoadMore: () => _loadMore(context, ref, s.key),
          ),
          const SizedBox(height: 12),
        ],
        if (data.exportedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.myDataExportedAt(
                AppDates.of(context).isoDateTime(data.exportedAt),
              ),
              textAlign: TextAlign.center,
              style: AppTypography.body3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _loadMore(
    BuildContext context,
    WidgetRef ref,
    String key,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(myDataControllerProvider.notifier).loadMore(key);
    } on DataExportAccountGone {
      if (context.mounted) await MyDataScreen._accountGone(context, ref);
    } catch (e) {
      final text = e is DataExportRateLimited
          ? (e.message ?? l10n.myDataRateLimited)
          : l10n.myDataLoadFailed;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final avatar = _str(profile['avatar_url']);
    final name = _str(profile['full_name']);
    final contact = _str(profile['phone']) ?? _str(profile['email']);
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.foundationBlue100,
          backgroundImage: avatar == null
              ? null
              : CachedNetworkImageProvider(avatar),
          child: avatar == null
              ? const Icon(Icons.person_rounded, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name ?? '-', style: AppTypography.heading4),
              if (contact != null)
                Text(
                  contact,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One collapsible card per section. The short ones (profile, preferences,
/// points) open expanded; the lists start collapsed.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onLoadMore});
  final MyDataSection section;
  final VoidCallback onLoadMore;

  static const _expanded = {'profile', 'notification_prefs', 'loyalty'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = section.isPaged
        ? '${section.title} (${fmtPoints(section.total)})'
        : section.title;
    final empty = section.isList && section.items.isEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.semanticGrayNeutralBorderLightgray),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: Key('myDataSection_${section.key}'),
        initiallyExpanded: _expanded.contains(section.key),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Text(title, style: AppTypography.heading5),
        children: [
          if (empty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.myDataEmpty,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ..._content(context, section),
          if (section.hasMore)
            Center(
              child: section.loadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: MassLoadingM(size: 28),
                    )
                  : TextButton(
                      key: Key('myDataMore_${section.key}'),
                      onPressed: onLoadMore,
                      child: Text(l10n.myDataLoadMore),
                    ),
            ),
          ..._editLink(context, section.key),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, MyDataSection s) {
    final d = s.data;
    switch (s.key) {
      case 'profile':
        return _profile(context, d);
      case 'notification_prefs':
        return _prefs(context, d);
      case 'loyalty':
        return _loyalty(context, d);
      case 'saved_places':
        return _rows(s.items, (i) => _place(context, i));
      case 'trips':
        return _rows(s.items, (i) => _trip(context, i));
      case 'orders':
        return _rows(s.items, (i) => _order(context, i));
      case 'points_history':
        return _rows(s.items, (i) => _points(context, i));
      case 'search_history':
        return _rows(s.items, (i) => _search(context, i));
      case 'consents':
        return _rows(s.items, (i) => _consent(context, i));
    }
    return const [];
  }

  static List<Widget> _rows(
    List<Map<String, dynamic>> items,
    Widget Function(Map<String, dynamic>) row,
  ) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) const Divider(height: 20),
      row(items[i]),
    ],
  ];

  List<Widget> _editLink(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    final (label, route) = switch (key) {
      'profile' => (l10n.myDataEditProfile, '/edit-profile'),
      'saved_places' => (l10n.myDataEditPlaces, '/saved-places'),
      // The marketing switch lives on the profile tab.
      'notification_prefs' => (l10n.myDataEditNotifications, '/profile'),
      _ => (null, null),
    };
    if (label == null || route == null) return const [];
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => context.push(route),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(label),
        ),
      ),
    ];
  }

  List<Widget> _profile(BuildContext context, Map<String, dynamic> d) {
    final l10n = AppLocalizations.of(context)!;
    final dates = AppDates.of(context);
    final contact = d['emergency_contact'];
    final prefs = d['ride_preferences'];
    final dob = DateTime.tryParse(_str(d['date_of_birth']) ?? '');
    return [
      _Field(l10n.myDataFullName, _str(d['full_name'])),
      _Field(l10n.myDataPhone, _str(d['phone'])),
      _Field(l10n.myDataEmail, _str(d['email'])),
      _Field(l10n.myDataBirthday, dob == null ? null : dates.date(dob)),
      _Field(l10n.myDataMemberSince, _date(context, d['created_at'])),
      if (contact is Map)
        _Field(
          l10n.myDataEmergencyContact,
          _join([
            contact['name'],
            contact['phone'],
            contact['relationship'],
          ], ' · '),
        ),
      if (prefs is Map && prefs.isNotEmpty)
        _Field(
          l10n.myDataRidePreferences,
          prefs.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
        ),
    ];
  }

  List<Widget> _prefs(BuildContext context, Map<String, dynamic> d) {
    final l10n = AppLocalizations.of(context)!;
    final lang = _str(d['language']);
    return [
      _Field(
        l10n.myDataMarketing,
        d['marketing_opt_in'] == true ? l10n.myDataOn : l10n.myDataOff,
      ),
      _Field(l10n.myDataLanguage, switch (lang) {
        'th' => 'ไทย',
        'en' => 'English',
        _ => lang,
      }),
    ];
  }

  List<Widget> _loyalty(BuildContext context, Map<String, dynamic> d) {
    final l10n = AppLocalizations.of(context)!;
    String pts(Object? v) => v is num ? fmtPoints(v) : '-';
    return [
      _Field(l10n.myDataPointsBalance, pts(d['balance'])),
      _Field(l10n.myDataPointsLifetime, pts(d['lifetime_points'])),
      _Field(l10n.myDataPointsRedeemed, pts(d['redeemed_points'])),
      _Field(l10n.myDataPointsExpired, pts(d['expired_points'])),
    ];
  }

  Widget _place(BuildContext context, Map<String, dynamic> p) {
    final l10n = AppLocalizations.of(context)!;
    return _Item(
      title: _str(p['name']) ?? '-',
      badge: p['is_default'] == true ? l10n.myDataDefault : null,
      fields: [
        _Field(null, _str(p['address'])),
        _Field(l10n.myDataNote, _str(p['note'])),
        _Field(l10n.myDataPhone, _str(p['phone_number'])),
      ],
    );
  }

  Widget _trip(BuildContext context, Map<String, dynamic> t) {
    final l10n = AppLocalizations.of(context)!;
    final stops = t['stops'] is List ? t['stops'] as List : const [];
    final rating = t['rating_by_customer'];
    return _Item(
      title: _str(t['status_label']) ?? '-',
      trailing: _dateTime(context, t['created_at']),
      fields: [
        _Field(l10n.myDataFrom, _str(t['pickup_address'])),
        for (final s in stops)
          if (s is Map)
            _Field(l10n.myDataStop, _str(s['address']) ?? _str(s['name'])),
        _Field(l10n.myDataTo, _str(t['dropoff_address'])),
        _Field(l10n.myDataFare, _baht(t['fare'])),
        if (t['discount'] is num && (t['discount'] as num) > 0)
          _Field(l10n.myDataDiscount, _baht(t['discount'])),
        _Field(l10n.myDataPayment, _payment(l10n, t['payment_method'])),
        _Field(l10n.myDataCompletedAt, _dateTime(context, t['completed_at'])),
        _Field(l10n.myDataCancelledAt, _dateTime(context, t['cancelled_at'])),
        _Field(l10n.myDataCancelReason, _str(t['cancel_reason'])),
        _Field(
          l10n.myDataYourRating,
          rating is num && rating > 0 ? '★ ${rating.toInt()}' : null,
        ),
        _Field(l10n.myDataYourComment, _str(t['customer_comment'])),
        _Field(l10n.myDataDriver, _driver(t['driver'])),
      ],
    );
  }

  Widget _order(BuildContext context, Map<String, dynamic> o) {
    final l10n = AppLocalizations.of(context)!;
    final food = o['type'] == 'FOOD';
    final items = o['items'] is List ? o['items'] as List : const [];
    return _Item(
      title: _join([
        food ? l10n.myDataOrderFood : l10n.myDataOrderMessenger,
        o['status_label'],
      ], ' · ')!,
      trailing: _dateTime(context, o['created_at']),
      fields: [
        if (food) ...[
          _Field(l10n.myDataRestaurant, _str(o['restaurant_name'])),
          _Field(l10n.myDataDeliveryAddress, _str(o['delivery_address'])),
          if (items.isNotEmpty)
            _Field(
              l10n.myDataItems,
              [
                for (final i in items)
                  if (i is Map) _foodItem(i),
              ].join('\n'),
            ),
        ] else ...[
          _Field(l10n.myDataFrom, _str(o['pickup_address'])),
          _Field(l10n.myDataTo, _str(o['dropoff_address'])),
          _Field(
            l10n.myDataRecipient,
            _join([o['recipient_name'], o['recipient_phone']], ' · '),
          ),
          _Field(l10n.myDataPackageSize, _str(o['package_size'])),
        ],
        _Field(l10n.myDataTotal, _baht(o['total'])),
        _Field(l10n.myDataPayment, _payment(l10n, o['payment_method'])),
        _Field(l10n.myDataDriver, _driver(o['driver'])),
      ],
    );
  }

  Widget _points(BuildContext context, Map<String, dynamic> p) {
    final n = p['points'];
    final pts = n is num ? (n > 0 ? '+${fmtPoints(n)}' : fmtPoints(n)) : null;
    return _Item(
      title: _str(p['description']) ?? _str(p['type']) ?? '-',
      trailing: pts,
      fields: [_Field(null, _dateTime(context, p['created_at']))],
    );
  }

  Widget _search(BuildContext context, Map<String, dynamic> q) => _Item(
    title: _str(q['query']) ?? '-',
    fields: [_Field(null, _dateTime(context, q['searched_at']))],
  );

  Widget _consent(BuildContext context, Map<String, dynamic> c) {
    final l10n = AppLocalizations.of(context)!;
    final withdrawn = c['granted'] != true || _str(c['withdrawn_at']) != null;
    return _Item(
      title: _str(c['consent_type']) ?? '-',
      badge: withdrawn
          ? l10n.myDataConsentWithdrawn
          : l10n.myDataConsentGranted,
      fields: [
        _Field(
          l10n.myDataConsentGrantedAt,
          _dateTime(context, c['granted_at']),
        ),
        _Field(
          l10n.myDataConsentWithdrawnAt,
          _dateTime(context, c['withdrawn_at']),
        ),
        _Field(l10n.myDataConsentVersion, _str(c['version'])),
      ],
    );
  }

  static String _foodItem(Map<dynamic, dynamic> i) {
    final line = '${i['quantity'] ?? 1}× ${i['name'] ?? '-'}';
    final price = _baht(i['subtotal']);
    final notes = _str(i['notes']);
    return [
      if (price != null) '$line  $price' else line,
      if (notes != null) '  ($notes)',
    ].join();
  }

  static String? _driver(Object? d) {
    if (d is! Map) return null;
    return _join([
      d['name'],
      d['vehicle_plate'],
      _join([d['vehicle_model'], d['vehicle_color']], ' '),
    ], ' · ');
  }

  static String? _payment(AppLocalizations l10n, Object? method) {
    final m = _str(method);
    if (m == null) return null;
    return switch (m.toUpperCase()) {
      'CASH' => l10n.cashLabel,
      'PROMPTPAY' => l10n.promptPay,
      'COD' => l10n.livePayCod,
      _ => m,
    };
  }

  static String? _baht(Object? v) => v is num ? '฿${fmtBaht(v)}' : null;

  static String? _date(BuildContext context, Object? iso) {
    final s = _str(iso);
    return s == null ? null : AppDates.of(context).isoDate(s);
  }

  static String? _dateTime(BuildContext context, Object? iso) {
    final s = _str(iso);
    return s == null ? null : AppDates.of(context).isoDateTime(s);
  }
}

/// A row in a list section: a bold title, an optional date or badge on the
/// right, then its fields.
class _Item extends StatelessWidget {
  const _Item({
    required this.title,
    required this.fields,
    this.trailing,
    this.badge,
  });

  final String title;
  final String? trailing;
  final String? badge;
  final List<_Field> fields;

  @override
  Widget build(BuildContext context) {
    final shown = fields.where((f) => f.value != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(title, style: AppTypography.label2)),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.foundationBlue100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: AppTypography.body3.copyWith(color: AppColors.primary),
                ),
              ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.body3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        for (final f in shown) ...[const SizedBox(height: 4), f],
      ],
    );
  }
}

/// A label and its value. A null value hides the row (a field the customer
/// never filled in); [label] null shows the value alone.
class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String? label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final valueText = Text(value!, style: AppTypography.body2);
    if (label == null) return valueText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 132,
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              label!,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: valueText),
        ],
      ),
    );
  }
}

class _ErrorView extends StatefulWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  State<_ErrorView> createState() => _ErrorViewState();
}

/// 429: the server's message as is, and the retry button counts down to the
/// moment the limit lets the customer in again. Anything else: retry now.
class _ErrorViewState extends State<_ErrorView> {
  Timer? _timer;
  int _wait = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.error;
    if (e is DataExportRateLimited) {
      _wait = e.retryAfter.inSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _wait--);
        if (_wait <= 0) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = widget.error;
    // The sign-out dialog handles a deleted account.
    if (e is DataExportAccountGone) return const SizedBox.shrink();
    final message = e is DataExportRateLimited
        ? (e.message ?? l10n.myDataRateLimited)
        : l10n.myDataLoadFailed;
    final waiting = _wait > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              key: const Key('myDataError'),
              textAlign: TextAlign.center,
              style: AppTypography.body1,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('myDataRetry'),
              onPressed: waiting ? null : widget.onRetry,
              child: Text(
                waiting ? l10n.myDataRetryIn(_wait) : l10n.myDataRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _str(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

String? _join(List<Object?> parts, String sep) {
  final kept = [for (final p in parts) ?_str(p)];
  return kept.isEmpty ? null : kept.join(sep);
}
