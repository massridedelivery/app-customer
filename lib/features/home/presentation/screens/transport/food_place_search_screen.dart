import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/place_search_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/home/presentation/states/place_search_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/features/home/domain/models/place.dart';
import 'package:customer_app/features/home/domain/models/place_prediction.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class FoodPlaceSearchScreen extends ConsumerStatefulWidget {
  const FoodPlaceSearchScreen({super.key});

  @override
  ConsumerState<FoodPlaceSearchScreen> createState() =>
      _FoodPlaceSearchScreenState();
}

class _FoodPlaceSearchScreenState extends ConsumerState<FoodPlaceSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);
    final searchState = ref.watch(placeSearchControllerProvider);

    // Listen to selection mode changes to pop back to FoodDeliveryScreen when confirmed via Map
    ref.listen(homeControllerProvider.select((s) => s.selectionMode), (
      prev,
      next,
    ) {
      if (prev == RideSelectionMode.food && next == RideSelectionMode.none) {
        if (context.mounted) {
          context.pop();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ระบุสถานที่ส่งอาหาร', style: AppTypography.heading4),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchInput(homeState),
            _buildTabs(),
            const SizedBox(height: 12),
            _buildMainContent(homeState, searchState),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput(HomeState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            AppIcons.asset(
              AppAssets.icLocationFill,
              width: 25,
              height: 25,
              color: AppColors.foundationRed700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => ref
                    .read(placeSearchControllerProvider.notifier)
                    .search(val),
                decoration: const InputDecoration(
                  hintText: 'ให้เราไปส่งอาหารที่ไหนดี?',
                  border: InputBorder.none,
                ),
                style: AppTypography.body1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTabItem(0, AppLocalizations.of(context)!.recent),
          const SizedBox(width: 12),
          _buildTabItem(1, AppLocalizations.of(context)!.recommended),
          const SizedBox(width: 12),
          _buildTabItem(2, AppLocalizations.of(context)!.saved),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String text) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.foundationBlue300 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppTypography.label1.copyWith(
            color: isSelected ? AppColors.primary : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(HomeState state, PlaceSearchState searchState) {
    if (searchState.results.isNotEmpty) {
      return Expanded(
        child: ListView.builder(
          itemCount: searchState.results.length,
          itemBuilder: (context, index) {
            final p = searchState.results[index];
            return _buildSearchItem(
              p.mainText.isNotEmpty ? p.mainText : p.description,
              p.secondaryText,
              icon: Icons.location_on,
              iconColor: AppColors.primary,
              onTap: () => _selectPrediction(p),
            );
          },
        ),
      );
    }

    if (searchState.isSearching) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentList(state.recentPlaces),
          Center(child: Text(AppLocalizations.of(context)!.recommended)),
          _buildSavedList(state.savedPlaces),
        ],
      ),
    );
  }

  Future<void> _selectPrediction(PlacePrediction p) async {
    final place = await ref
        .read(placeSearchControllerProvider.notifier)
        .resolveDetails(p);
    if (place == null || !mounted) return;
    ref
        .read(homeControllerProvider.notifier)
        .setFoodLocation(
          LatLng(place.lat, place.lng),
          place.address ?? place.name,
        );
    if (context.mounted) context.pop();
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: InkWell(
        onTap: () {
          ref
              .read(homeControllerProvider.notifier)
              .startSelection(mode: RideSelectionMode.food);
          context.push('/food-location-selection');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Colors.black),
            const SizedBox(width: 8),
            const Text(
              'เลือกบนแผนที่',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentList(List<Place> recentPlaces) {
    if (recentPlaces.isEmpty) {
      return Center(
        child: Text(
          'ยังไม่มีสถานที่ล่าสุด',
          style: AppTypography.body2.copyWith(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: recentPlaces.length,
      itemBuilder: (context, index) {
        final p = recentPlaces[index];
        return _buildSearchItem(
          p.name,
          p.address ?? '',
          icon: Icons.access_time_filled,
          iconColor: Colors.blueGrey,
          onTap: () {
            ref
                .read(homeControllerProvider.notifier)
                .setFoodLocation(
                  LatLng(p.lat, p.lng),
                  p.address ?? p.name,
                );
            context.pop();
          },
        );
      },
    );
  }

  Widget _buildSearchItem(
    String title,
    String subtitle, {
    required IconData icon,
    required Color iconColor,
    bool isDefault = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: AppTypography.caption4.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDefault) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 14,
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption5.copyWith(color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }

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

  Widget _buildSavedList(List<Place> savedPlaces) {
    if (savedPlaces.isEmpty) {
      return Center(
        child: Text(
          'ยังไม่มีสถานที่ที่บันทึกไว้',
          style: AppTypography.body2.copyWith(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: savedPlaces.length,
      itemBuilder: (context, index) {
        final p = savedPlaces[index];
        return _buildSearchItem(
          p.name,
          p.address ?? '',
          icon: _iconFor(p.name),
          iconColor: AppColors.primary,
          isDefault: p.isDefault == true,
          onTap: () {
            ref
                .read(homeControllerProvider.notifier)
                .setFoodLocation(
                  LatLng(p.lat, p.lng),
                  p.address ?? p.name,
                );
            context.pop();
          },
        );
      },
    );
  }
}
