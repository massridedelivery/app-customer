import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:customer_app/features/food_order/presentation/states/checkout_state.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_cart_controller.dart';
import 'package:customer_app/features/food_order/presentation/widgets/checkout_coupon_section.dart';
import 'package:customer_app/features/food_order/presentation/widgets/checkout_delivery_address.dart';
import 'package:customer_app/features/food_order/presentation/widgets/checkout_delivery_options.dart';
import 'package:customer_app/features/food_order/presentation/widgets/checkout_order_items.dart';
import 'package:customer_app/features/food_order/presentation/widgets/checkout_payment_section.dart';
import 'package:customer_app/features/food_order/presentation/widgets/checkout_save_the_world.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/home/domain/usecases/get_default_place_usecase_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEstimate();
    });
  }

  Future<void> _loadEstimate() async {
    final cart = ref.read(foodCartControllerProvider);
    var homeState = ref.read(homeControllerProvider);

    // Bind default place if foodAddress is empty
    if (homeState.foodAddress == null || homeState.foodAddress!.isEmpty) {
      final defaultPlaces = homeState.savedPlaces.where((p) => p.isDefault == true);
      if (defaultPlaces.isNotEmpty) {
        final defaultPlace = defaultPlaces.first;
        ref.read(homeControllerProvider.notifier).setFoodLocation(
              LatLng(defaultPlace.lat, defaultPlace.lng),
              defaultPlace.address ?? defaultPlace.name,
            );
        // Refresh local variable reference to get the updated state
        homeState = ref.read(homeControllerProvider);
      } else {
        // Fetch from API directly
        try {
          final place = await ref.read(getDefaultPlaceUseCaseProvider).call();
          if (place != null) {
            ref.read(homeControllerProvider.notifier).setFoodLocation(
                  LatLng(place.lat, place.lng),
                  place.address ?? place.name,
                );
            // Refresh local variable reference to get the updated state
            homeState = ref.read(homeControllerProvider);
          }
        } catch (e) {
          debugPrint('No default place from API: $e');
        }
      }
    }

    if (cart.restaurantId != null && cart.items.isNotEmpty) {
      final location =
          homeState.foodLocation ??
          homeState.pickupLocation ??
          homeState.currentLocation;
      final lat = location?.latitude ?? 13.7563;
      final lng = location?.longitude ?? 100.5018;
      ref.read(checkoutProvider.notifier).loadEstimate(
            restaurantId: cart.restaurantId!,
            cartItems: cart.items,
            lat: lat,
            lng: lng,
          );
    }
  }

  void _onPlaceOrder() {
    final cart = ref.read(foodCartControllerProvider);
    final homeState = ref.read(homeControllerProvider);
    final location =
        homeState.foodLocation ??
        homeState.pickupLocation ??
        homeState.currentLocation;
    final lat = location?.latitude ?? 13.7563;
    final lng = location?.longitude ?? 100.5018;

    if (cart.restaurantId == null || cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีสินค้าในตะกร้า')),
      );
      return;
    }

    final address = homeState.foodAddress ?? 'ที่อยู่ปัจจุบัน';

    ref.read(checkoutProvider.notifier).submitOrder(
          restaurantId: cart.restaurantId!,
          cartItems: cart.items,
          lat: lat,
          lng: lng,
          address: address,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(foodCartControllerProvider);
    final cartNotifier = ref.read(foodCartControllerProvider.notifier);
    final checkoutState = ref.watch(checkoutProvider);

    // Listen for side effects
    ref.listen<CheckoutState>(checkoutProvider, (previous, next) {
      if (next.placedOrder != null && previous?.placedOrder == null) {
        ref.read(foodCartControllerProvider.notifier).clearCart();
        context.pushReplacement('/food-order/tracking/${next.placedOrder!.id}');
      }
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Listen for foodLocation and savedPlaces changes to reload estimate and bind default address
    ref.listen<HomeState>(homeControllerProvider, (previous, next) {
      // 1. Bind default place if foodAddress is empty and savedPlaces has a default place
      if (next.foodAddress == null || next.foodAddress!.isEmpty) {
        final defaultPlaces = next.savedPlaces.where((p) => p.isDefault == true);
        if (defaultPlaces.isNotEmpty) {
          final defaultPlace = defaultPlaces.first;
          ref.read(homeControllerProvider.notifier).setFoodLocation(
                LatLng(defaultPlace.lat, defaultPlace.lng),
                defaultPlace.address ?? defaultPlace.name,
              );
          return;
        }
      }

      // 2. Reload estimate if food location changed
      if (previous?.foodLocation != next.foodLocation) {
        _loadEstimate();
      }
    });

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('เช็คเอาท์')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('ไม่มีสินค้าในตะกร้าของคุณ', style: AppTypography.heading4),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('กลับไปสั่งอาหาร', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final double foodSubtotal = cartNotifier.foodTotal;
    double deliveryFee = 0.0;

    final tiers = checkoutState.estimate?.tiers ?? [];
    DeliveryTierModel? selectedTier;
    for (final t in tiers) {
      if (t.tier == checkoutState.selectedDeliveryOption) {
        selectedTier = t;
        break;
      }
    }

    if (selectedTier != null) {
      deliveryFee = selectedTier.deliveryFee;
    } else {
      if (checkoutState.selectedDeliveryOption == 'PRIORITY') {
        deliveryFee = 45;
      } else if (checkoutState.selectedDeliveryOption == 'SAVER') {
        deliveryFee = 15;
      } else {
        deliveryFee = 25;
      }
    }

    final double totalAmount = (foodSubtotal + deliveryFee - checkoutState.validatedPromoDiscount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          cart.restaurantName ?? 'สรุปรายการสั่งซื้อ',
          style: AppTypography.heading4,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: checkoutState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildPromoSuggestionBanner(checkoutState, foodSubtotal),
                  const CheckoutOrderItems(),
                  _buildDivider(),
                  const CheckoutDeliveryAddress(),
                  _buildDivider(),
                  const CheckoutDeliveryOptions(),
                  _buildDivider(),
                  const CheckoutCouponSection(),
                  _buildDivider(),
                  const CheckoutPaymentSection(),
                  // Cutlery choice isn't sent in the order body (SCRUM-44).
                  if (FeatureFlags.foodCutleryToggle) ...[
                    _buildDivider(),
                    const CheckoutSaveTheWorld(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomCheckoutBar(totalAmount, checkoutState.isPlacingOrder),
    );
  }

  Widget _buildDivider() {
    return Container(height: 8, color: Colors.grey[100]);
  }

  Widget _buildBottomCheckoutBar(double totalAmount, bool isPlacingOrder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isPlacingOrder ? null : _onPlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.foundationGreen500,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: isPlacingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'สั่งเลย - ฿${totalAmount.toStringAsFixed(0)}',
                      style: AppTypography.heading5.copyWith(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoSuggestionBanner(CheckoutState checkoutState, double foodSubtotal) {
    PromoSuggestionModel? almostUsablePromo;
    for (final s in checkoutState.suggestions) {
      if (s.status == 'ALMOST_USABLE' && s.promo.scope == 'DELIVERY') {
        almostUsablePromo = s;
        break;
      }
    }

    if (almostUsablePromo == null) return const SizedBox.shrink();

    final amountNeeded = almostUsablePromo.amountNeeded ?? 0.0;
    final minSpend = almostUsablePromo.promo.minSpend;
    final progress = minSpend > 0 ? (foodSubtotal / minSpend).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Light Amber
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                color: Color(0xFFFF8F00), // Dark Amber
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add ${amountNeeded.toStringAsFixed(0)} THB more to unlock Free Delivery!',
                  style: AppTypography.caption3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF8F00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFFFECB3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8F00)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
