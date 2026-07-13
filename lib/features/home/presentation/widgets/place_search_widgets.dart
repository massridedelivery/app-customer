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
          color: hasFocus ? AppColors.primary : Colors.grey.shade300,
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
    final searchResults = ref.watch(
      placeSearchControllerProvider.select((s) => s.results),
    );
    final isSearching = ref.watch(
      placeSearchControllerProvider.select((s) => s.isSearching),
    );

    if (searchResults.isNotEmpty) {
      return Expanded(
        child: ListView.builder(
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final PlacePrediction p = searchResults[index];
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

    if (isSearching) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Expanded(
      child: TabBarView(
        controller: tabController,
        children: [
          PlaceSearchPlaceList(
            places: ref.watch(
              homeControllerProvider.select((s) => s.recentPlaces),
            ),
            emptyText: AppLocalizations.of(context)!.recent,
            icon: Icons.access_time_filled,
            onSelectPlace: onSelectPlace,
          ),
          Center(child: Text(AppLocalizations.of(context)!.recommended)),
          PlaceSearchPlaceList(
            places: ref.watch(
              homeControllerProvider.select((s) => s.savedPlaces),
            ),
            emptyText: AppLocalizations.of(context)!.saved,
            icon: Icons.favorite,
            iconColor: Colors.redAccent,
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
    onSelectPlace(
      LatLng(place.lat, place.lng),
      place.address ?? place.name,
    );
  }
}

/// Renders a list of [Place]s (recent or saved) with a shared empty state.
class PlaceSearchPlaceList extends StatelessWidget {
  final List<Place> places;
  final String emptyText;
  final IconData icon;
  final Color iconColor;
  final void Function(LatLng, String) onSelectPlace;

  const PlaceSearchPlaceList({
    super.key,
    required this.places,
    required this.emptyText,
    required this.icon,
    required this.onSelectPlace,
    this.iconColor = Colors.blueGrey,
  });

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: AppTypography.body2.copyWith(color: Colors.grey),
        ),
      );
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
          onTap: () => onSelectPlace(
            LatLng(p.lat, p.lng),
            p.address ?? p.name,
          ),
        );
      },
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
            color: Colors.grey[100],
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
        subtitle: Text(
          subtitle,
          style: AppTypography.caption5.copyWith(color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.more_vert, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
