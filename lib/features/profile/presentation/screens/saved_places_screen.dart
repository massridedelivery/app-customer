import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/profile/presentation/controllers/saved_places_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SavedPlacesScreen extends ConsumerStatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  ConsumerState<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends ConsumerState<SavedPlacesScreen> {
  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(savedPlacesControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profileSavedPlacesTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          stateAsync.when(
            loading: () => const Center(child: MassLoadingM(size: 72)),
            error: (e, s) => Center(
              child: Text(l10n.profileLoadFailed, style: AppTypography.body2),
            ),
            data: (stateData) {
              return stateData.places.when(
                loading: () => const Center(child: MassLoadingM(size: 72)),
                error: (e, s) => Center(
                  child: Text(
                    l10n.profileLoadFailed,
                    style: AppTypography.body2,
                  ),
                ),
                data: (places) => places.isEmpty
                    ? const _EmptyPlaces()
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: places.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (c, i) {
                          final p = places[i];
                          return _PlaceCard(
                            place: p,
                            onDelete: () => _deletePlace(p.id ?? ''),
                          );
                        },
                      ),
              );
            },
          ),
          if (stateAsync.value?.isDeleting == true)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: MassLoadingM(size: 72),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/add-address');
          ref.read(savedPlacesControllerProvider.notifier).refreshPlaces();
        },
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(l10n.addAddress, style: AppTypography.label2),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _deletePlace(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeleteAddressTitle),
        content: Text(l10n.profileDeleteAddressConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              l10n.profileDelete,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await ref
          .read(savedPlacesControllerProvider.notifier)
          .deletePlace(id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileDeleteAddressFailed)),
        );
      }
    }
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onDelete;

  const _PlaceCard({required this.place, required this.onDelete});

  IconData _iconFor(String? name) {
    final lowerName = name?.toLowerCase() ?? '';
    if (lowerName.contains('home') || lowerName.contains('บ้าน')) {
      return Icons.home_rounded;
    }
    if (lowerName.contains('work') ||
        lowerName.contains('ที่ทำงาน') ||
        lowerName.contains('office')) {
      return Icons.work_rounded;
    }
    return Icons.location_on_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.foundationBlue100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconFor(place.name),
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        place.name,
                        style: AppTypography.heading4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (place.isDefault == true) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  place.address ??
                      AppLocalizations.of(context)!.profileNoAddressInfo,
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
  // The add affordance is the Scaffold FAB (shown in every state), so the
  // empty state is just the centered message — no second "เพิ่มที่อยู่" button.
  const _EmptyPlaces();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 72,
              color: Color(0xFFCFD1D9),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.profileNoSavedAddresses,
              style: AppTypography.heading4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profileNoSavedAddressesHint,
              style: AppTypography.body2.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
