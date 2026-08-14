import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/map_defaults.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:customer_app/features/food_delivery/data/repositories/food_discovery_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "ร้านที่บันทึกไว้" — the customer's favorited restaurants, backed by
/// `GET /api/discovery/saved`. Opened from the home-header heart button.
/// Tapping a row opens the restaurant; tapping the heart unfavorites it
/// (same endpoint pair the restaurant-detail heart uses).
class SavedRestaurantsScreen extends ConsumerStatefulWidget {
  const SavedRestaurantsScreen({super.key});

  @override
  ConsumerState<SavedRestaurantsScreen> createState() =>
      _SavedRestaurantsScreenState();
}

class _SavedRestaurantsScreenState
    extends ConsumerState<SavedRestaurantsScreen> {
  List<RestaurantProfileModel>? _restaurants;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _restaurants = null;
      _error = null;
    });
    try {
      // Distance/fee estimates need a reference point; fall back to the map
      // default when GPS hasn't resolved yet.
      final home = ref.read(homeControllerProvider);
      final loc =
          home.foodLocation ?? home.currentLocation ?? MapDefaults.bangkokCenter;
      final list = await ref
          .read(foodDiscoveryRepositoryProvider)
          .getSavedRestaurants(lat: loc.latitude, lng: loc.longitude);
      if (mounted) setState(() => _restaurants = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _unfavorite(RestaurantProfileModel rest) async {
    // Optimistic removal; restore on failure.
    final previous = _restaurants;
    setState(
      () => _restaurants =
          _restaurants?.where((r) => r.id != rest.id).toList(),
    );
    try {
      await ref
          .read(foodDiscoveryRepositoryProvider)
          .unfavoriteRestaurant(rest.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _restaurants = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เอาออกจากรายการโปรดไม่สำเร็จ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        title: const Text('ร้านที่บันทึกไว้', style: AppTypography.heading4),
        backgroundColor: AppColors.semanticGrayNeutralBgWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _centered(
        icon: Icons.cloud_off_outlined,
        message: 'โหลดร้านที่บันทึกไว้ไม่สำเร็จ\nแตะเพื่อลองใหม่',
        onTap: _load,
      );
    }
    final restaurants = _restaurants;
    if (restaurants == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (restaurants.isEmpty) {
      return _centered(
        icon: Icons.favorite_border,
        message: 'ยังไม่มีร้านที่บันทึกไว้\nแตะรูปหัวใจในหน้าร้านเพื่อบันทึก',
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: restaurants.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 128),
      itemBuilder: (context, index) => _restaurantTile(restaurants[index]),
    );
  }

  Widget _restaurantTile(RestaurantProfileModel rest) {
    return InkWell(
      onTap: () => context.push('/restaurant/${rest.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppNetworkImage(
                url: rest.imageUrl,
                width: 100,
                height: 100,
                fallbackIcon: Icons.restaurant,
                fallbackIconSize: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rest.restaurantName,
                    style: AppTypography.caption4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rest.rating.toStringAsFixed(1),
                        style: AppTypography.caption5.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      if (rest.distanceKm != null)
                        Text(
                          ' • ${rest.distanceKm!.toStringAsFixed(1)} กม.',
                          style: AppTypography.caption5.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!rest.isOpen)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ปิดทำการ',
                        style: AppTypography.caption5.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _unfavorite(rest),
              icon: const Icon(Icons.favorite, color: AppColors.primary),
              tooltip: 'เอาออกจากรายการโปรด',
            ),
          ],
        ),
      ),
    );
  }

  Widget _centered({
    required IconData icon,
    required String message,
    VoidCallback? onTap,
  }) {
    // Wrapped in a scrollable so RefreshIndicator still works on empty/error.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
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
          ),
        ),
      ),
    );
  }
}
