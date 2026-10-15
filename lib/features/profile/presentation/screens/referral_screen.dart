import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/data/datasources/referral_remote_data_source.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final referralInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(referralRemoteDataSourceProvider).getInfo();
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralInfoProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profileReferralTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: referralAsync.when(
        loading: () => const Center(child: MassLoadingM(size: 72)),
        error: (e, s) => Center(
          child: Text(l10n.profileLoadFailed, style: AppTypography.body2),
        ),
        data: (referral) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Hero illustration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.accentRedDeep],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.group_add_rounded,
                      size: 64,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.profileReferralHeadline,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.profileReferralSubtitle,
                      style: AppTypography.body2.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Stats
              Row(
                children: [
                  _ReferralStat(
                    label: l10n.profileReferralFriendsInvited,
                    value: '${referral['referral_count'] ?? 0}',
                    icon: Icons.people_rounded,
                  ),
                  const SizedBox(width: 12),
                  _ReferralStat(
                    label: l10n.profileReferralPointsEarned,
                    value: '${referral['total_earned_points'] ?? 0}',
                    icon: Icons.stars_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Code section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E2E1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.profileReferralYourCode,
                      style: AppTypography.support1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.foundationBlue100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        referral['code'] ?? 'MASS-XXXX',
                        style: AppTypography.heading2.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: referral['code'] ?? ''),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.profileReferralCodeCopied),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(l10n.profileReferralCopy),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final code = referral['code'] ?? '';
                              Clipboard.setData(
                                ClipboardData(
                                  text: l10n.profileReferralShareMessage(
                                    '$code',
                                  ),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.profileReferralInviteCopied,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(l10n.profileReferralShare),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Apply referral
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E2E1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileReferralHaveCode,
                      style: AppTypography.heading4,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.profileReferralHaveCodeSubtitle,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ApplyReferralField(ref: ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReferralStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.heading3.copyWith(color: AppColors.primary),
            ),
            Text(
              label,
              style: AppTypography.caption5.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplyReferralField extends StatefulWidget {
  final WidgetRef ref;
  const _ApplyReferralField({required this.ref});

  @override
  State<_ApplyReferralField> createState() => _ApplyReferralFieldState();
}

class _ApplyReferralFieldState extends State<_ApplyReferralField> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: l10n.profileReferralCodeHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _loading ? null : () => _applyCode(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.profileReferralApply),
        ),
      ],
    );
  }

  Future<void> _applyCode(BuildContext context) async {
    if (_ctrl.text.isEmpty) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.ref
          .read(referralRemoteDataSourceProvider)
          .applyCode(_ctrl.text.trim());
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.profileReferralApplySuccess)),
        );
        _ctrl.clear();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.profileReferralApplyInvalid)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
