import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/place_search_controller.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchInputContainer extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;

  const SearchInputContainer({
    super.key,
    required this.focusNode,
    required this.child,
  });

  @override
  State<SearchInputContainer> createState() => _SearchInputContainerState();
}

class _SearchInputContainerState extends State<SearchInputContainer> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant SearchInputContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = widget.focusNode.hasFocus;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: hasFocus
              ? AppColors.primary
              : AppColors.semanticGrayNeutralBorderMidgray,
          width: hasFocus ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.child,
    );
  }
}

class PlaceSearchMainContent extends ConsumerWidget {
  final TabController tabController;
  final void Function(LatLng, String) onSelectPlace;

  const PlaceSearchMainContent({
    super.key,
    required this.tabController,
    required this.onSelectPlace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final searchState = ref.watch(placeSearchControllerProvider);

    if (searchState.hasError) {
      return Expanded(
        child: _SearchErrorView(
          message: l10n.searchError,
          onRetry: () =>
              ref.read(placeSearchControllerProvider.notifier).retry(),
        ),
      );
    }

    if (searchState.results.isNotEmpty) {
      return Expanded(
        child: ListView.builder(
          itemCount: searchState.results.length,
          itemBuilder: (context, index) {
            final PlacePrediction p = searchState.results[index];
            return SearchItem(
              title: p.mainText.isNotEmpty ? p.mainText : p.description,
              subtitle: p.secondaryText,
              icon: Icons.location_on,
              iconColor: AppColors.primary,
              onTap: () => _selectPrediction(ref, p),
            );
          },
        ),
      );
    }

    if (searchState.isSearching) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    return Expanded(
      child: TabBarView(
        controller: tabController,
        children: [
          PlaceSearchPlaceList(
            places: ref.watch(
              homeControllerProvider.select((s) => s.recentPlaces),
            ),
            emptyMessage: l10n.noRecentSearches,
            emptyIcon: Icons.history,
            icon: Icons.access_time_filled,
            onSelectPlace: onSelectPlace,
          ),
          _PlaceSearchEmpty(
            icon: Icons.star_outline,
            message: l10n.recommendedEmpty,
          ),
          PlaceSearchPlaceList(
            places: ref.watch(
              homeControllerProvider.select((s) => s.savedPlaces),
            ),
            emptyMessage: l10n.noSavedPlaces,
            emptyIcon: Icons.favorite_border,
            icon: Icons.favorite,
            iconColor: AppColors.secondaryRed,
            onSelectPlace: onSelectPlace,
          ),
        ],
      ),
    );
  }

  Future<void> _selectPrediction(WidgetRef ref, PlacePrediction p) async {
    final place = await ref
        .read(placeSearchControllerProvider.notifier)
        .resolveDetails(p);
    if (place == null) return;
    onSelectPlace(LatLng(place.lat, place.lng), place.address ?? place.name);
  }
}

/// Renders a list of [Place]s (recent or saved) with a shared empty state.
class PlaceSearchPlaceList extends StatelessWidget {
  final List<Place> places;
  final String emptyMessage;
  final IconData emptyIcon;
  final IconData icon;
  final Color iconColor;
  final void Function(LatLng, String) onSelectPlace;

  const PlaceSearchPlaceList({
    super.key,
    required this.places,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.icon,
    required this.onSelectPlace,
    this.iconColor = Colors.blueGrey,
  });

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return _PlaceSearchEmpty(icon: emptyIcon, message: emptyMessage);
    }
    return ListView.builder(
      itemCount: places.length,
      itemBuilder: (context, index) {
        final p = places[index];
        return SearchItem(
          title: p.name,
          subtitle: p.address ?? '',
          icon: icon,
          iconColor: iconColor,
          onTap: () => onSelectPlace(LatLng(p.lat, p.lng), p.address ?? p.name),
        );
      },
    );
  }
}

/// Shared empty-state placeholder: a muted icon above a short message.
class _PlaceSearchEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _PlaceSearchEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.semanticGrayNeutralFgLowOnWhite),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(
              color: AppColors.semanticGrayNeutralFgMidOnWhite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error placeholder with a retry affordance for a failed autocomplete call.
class _SearchErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SearchErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.semanticGrayNeutralFgLowOnWhite,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body2.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const SearchItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.semanticGrayNeutralBgLightgray,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: AppTypography.caption4.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: AppTypography.caption5.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnWhite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        onTap: onTap,
      ),
    );
  }
}
