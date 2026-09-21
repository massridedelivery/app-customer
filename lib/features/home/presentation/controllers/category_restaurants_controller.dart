import 'package:customer_app/core/constants/map_defaults.dart';
import 'package:customer_app/features/food_delivery/data/repositories/food_discovery_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_restaurants_controller.g.dart';

/// One page's worth of category-browse state (SCRUM-8): the accumulated
/// restaurants plus whether more can be fetched and whether a fetch is in
/// flight, so the UI can append an endless-scroll footer.
class CategoryFeed {
  const CategoryFeed({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<RestaurantProfileModel> items;
  final bool hasMore;
  final bool loadingMore;

  CategoryFeed copyWith({
    List<RestaurantProfileModel>? items,
    bool? hasMore,
    bool? loadingMore,
  }) => CategoryFeed(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Paginated restaurants for a category (SCRUM-8). Loads the first page in
/// [build] and appends further pages via [loadMore]; `hasMore` is inferred from
/// a full page coming back (a short page means the end).
@riverpod
class CategoryRestaurants extends _$CategoryRestaurants {
  static const int _pageSize = 20;

  @override
  FutureOr<CategoryFeed> build(String categoryId) async {
    final page = await _fetch(offset: 0);
    return CategoryFeed(items: page, hasMore: page.length == _pageSize);
  }

  Future<List<RestaurantProfileModel>> _fetch({required int offset}) {
    final location = ref.read(homeControllerProvider);
    final loc =
        location.foodLocation ??
        location.pickupLocation ??
        location.currentLocation;
    final repo = ref.read(foodDiscoveryRepositoryProvider);
    return repo.getCategoryRestaurants(
      categoryId: categoryId,
      lat: loc?.latitude ?? MapDefaults.bangkokLat,
      lng: loc?.longitude ?? MapDefaults.bangkokLng,
      limit: _pageSize,
      offset: offset,
    );
  }

  /// Fetches the next page and appends it. No-op while a page is already in
  /// flight or when the end has been reached.
  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _fetch(offset: current.items.length);
      state = AsyncData(
        CategoryFeed(
          items: [...current.items, ...next],
          hasMore: next.length == _pageSize,
        ),
      );
    } catch (_) {
      // Keep what we have and let the user trigger another scroll to retry.
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

/// Paginated restaurants for a home-feed section (SCRUM-8,
/// `GET /api/discovery/sections/:id`). Same paging shape as
/// [CategoryRestaurants], just a different source endpoint — used by the
/// section "ดูทั้งหมด" browse.
@riverpod
class SectionRestaurants extends _$SectionRestaurants {
  static const int _pageSize = 20;

  @override
  FutureOr<CategoryFeed> build(String sectionId) async {
    final page = await _fetch(offset: 0);
    return CategoryFeed(items: page, hasMore: page.length == _pageSize);
  }

  Future<List<RestaurantProfileModel>> _fetch({required int offset}) {
    final location = ref.read(homeControllerProvider);
    final loc =
        location.foodLocation ??
        location.pickupLocation ??
        location.currentLocation;
    final repo = ref.read(foodDiscoveryRepositoryProvider);
    return repo.getSectionRestaurants(
      sectionId: sectionId,
      lat: loc?.latitude ?? MapDefaults.bangkokLat,
      lng: loc?.longitude ?? MapDefaults.bangkokLng,
      limit: _pageSize,
      offset: offset,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _fetch(offset: current.items.length);
      state = AsyncData(
        CategoryFeed(
          items: [...current.items, ...next],
          hasMore: next.length == _pageSize,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}
