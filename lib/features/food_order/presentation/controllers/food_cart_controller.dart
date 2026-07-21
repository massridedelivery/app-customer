import 'dart:async';

import 'package:customer_app/features/food_order/data/repositories/food_order_repository_impl.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:customer_app/features/food_order/presentation/states/food_cart_state.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'food_cart_controller.g.dart';

@Riverpod(keepAlive: true)
class FoodCartController extends _$FoodCartController {
  Timer? _syncDebounce;
  bool _hasRestored = false;

  @override
  FoodCartState build() {
    ref.onDispose(() => _syncDebounce?.cancel());
    // Restore a server-persisted cart so it survives an app restart (A2).
    Future.microtask(_restoreFromServer);
    return const FoodCartState();
  }

  /// Rebuild the cart from `GET /api/food/customer/cart` on first load
  /// (SCRUM-44 A2). The server cart is thin, so fetch the restaurant menu and
  /// match menu_item_id (+ modifier names, best-effort) to reconstruct full
  /// CartItems. Never clobbers a cart the user already started, and never
  /// re-syncs what it just read.
  Future<void> _restoreFromServer() async {
    if (_hasRestored || state.items.isNotEmpty) return;
    _hasRestored = true;
    try {
      final repo = ref.read(foodOrderRepositoryProvider);
      final remote = await repo.getCart();
      if (remote.restaurantId.isEmpty ||
          remote.items.isEmpty ||
          state.items.isNotEmpty) {
        return;
      }

      final menu = await repo.getRestaurantMenu(remote.restaurantId);
      final menuById = <String, MenuItemModel>{};
      for (final category in menu) {
        for (final item in category.items) {
          menuById[item.id] = item;
        }
      }

      String imageUrl = '';
      final restored = <CartItem>[];
      for (final r in remote.items) {
        final item = menuById[r.menuItemId];
        if (item == null) continue; // no longer on the menu — drop it
        if (imageUrl.isEmpty) imageUrl = item.imageUrl ?? '';

        // The server cart carries modifier names, not ids — match by name
        // across the item's groups (best-effort).
        final byName = <String, ModifierModel>{
          for (final group in item.modifierGroups)
            for (final m in group.modifiers) m.name: m,
        };
        final mods = <ModifierModel>[];
        for (final name in r.modifierNames) {
          final m = byName[name];
          if (m != null) mods.add(m);
        }

        restored.add(
          CartItem(
            item: item,
            quantity: r.quantity,
            selectedModifiers: mods,
            notes: r.notes,
          ),
        );
      }

      // Re-check: the user may have added something during the async fetch.
      if (restored.isEmpty || state.items.isNotEmpty) return;
      state = state.copyWith(
        restaurantId: remote.restaurantId,
        restaurantName: remote.restaurantName,
        restaurantImageUrl: imageUrl,
        items: restored,
      );
    } catch (e) {
      debugPrint('FoodCartController: cart restore failed: $e');
    }
  }

  /// Push the whole cart to the server after local edits settle
  /// (SCRUM-44 Screen 4, `PUT /api/food/customer/cart`). Debounced so a burst
  /// of +/- taps sends one request; optimistic — the local state is the source
  /// of truth for the UI and a failed sync never blocks it.
  void _scheduleSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 600), _syncToServer);
  }

  Future<void> _syncToServer() async {
    final restaurantId = state.restaurantId;
    // Nothing to upsert without a restaurant; an emptied cart is left for the
    // backend to clear on order placement (no clear endpoint in the spec).
    if (restaurantId == null || restaurantId.isEmpty || state.items.isEmpty) {
      return;
    }
    final items = state.items
        .map(
          (c) => <String, dynamic>{
            'menu_item_id': c.item.id,
            'quantity': c.quantity,
            if (c.selectedModifiers.isNotEmpty)
              'modifier_ids': c.selectedModifiers.map((m) => m.id).toList(),
            if (c.notes.isNotEmpty) 'notes': c.notes,
          },
        )
        .toList();
    try {
      await ref
          .read(foodOrderRepositoryProvider)
          .upsertCart(restaurantId: restaurantId, items: items);
    } catch (e) {
      debugPrint('FoodCartController: cart sync failed: $e');
    }
  }

  bool addItem({
    required MenuItemModel item,
    required int quantity,
    required List<ModifierModel> selectedModifiers,
    required String restaurantId,
    required String restaurantName,
    required String restaurantImageUrl,
    String notes = '',
  }) {
    if (state.restaurantId != null &&
        state.restaurantId != restaurantId &&
        state.items.isNotEmpty) {
      return false;
    }

    final newItems = List<CartItem>.from(state.items);

    int existingIndex = -1;
    for (int i = 0; i < newItems.length; i++) {
      if (newItems[i].item.id == item.id) {
        final m1 = newItems[i].selectedModifiers.map((e) => e.id).toSet();
        final m2 = selectedModifiers.map((e) => e.id).toSet();
        // Same item + same modifiers + same note stack together; a different
        // note is a distinct line so the kitchen sees each instruction.
        if (m1.length == m2.length &&
            m1.containsAll(m2) &&
            newItems[i].notes == notes) {
          existingIndex = i;
          break;
        }
      }
    }

    if (existingIndex >= 0) {
      final existingItem = newItems[existingIndex];
      newItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      newItems.add(
        CartItem(
          item: item,
          quantity: quantity,
          selectedModifiers: selectedModifiers,
          notes: notes,
        ),
      );
    }

    state = state.copyWith(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImageUrl: restaurantImageUrl,
      items: newItems,
    );
    _scheduleSync();
    return true;
  }

  void forceAddItem({
    required MenuItemModel item,
    required int quantity,
    required List<ModifierModel> selectedModifiers,
    required String restaurantId,
    required String restaurantName,
    required String restaurantImageUrl,
    String notes = '',
  }) {
    state = FoodCartState(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImageUrl: restaurantImageUrl,
      items: [
        CartItem(
          item: item,
          quantity: quantity,
          selectedModifiers: selectedModifiers,
          notes: notes,
        ),
      ],
    );
    _scheduleSync();
  }

  void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= state.items.length) return;
    final newItems = List<CartItem>.from(state.items);
    if (quantity <= 0) {
      newItems.removeAt(index);
    } else {
      newItems[index] = newItems[index].copyWith(quantity: quantity);
    }

    if (newItems.isEmpty) {
      state = const FoodCartState();
    } else {
      state = state.copyWith(items: newItems);
    }
    _scheduleSync();
  }

  void removeItem(int index) {
    updateQuantity(index, 0);
  }

  void clearCart() {
    state = const FoodCartState();
    _scheduleSync();
  }

  double get foodTotal => state.foodTotal;

  int get totalQuantity => state.totalQuantity;
}

/// Cart totals derived from state, exposed as an extension so widgets can
/// `ref.watch(foodCartControllerProvider.select((s) => s.totalQuantity))` and
/// rebuild only when the derived number changes — instead of watching the
/// whole controller and rebuilding on every unrelated field change.
extension FoodCartTotals on FoodCartState {
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get foodTotal {
    double total = 0.0;
    for (final cartItem in items) {
      double itemPrice = cartItem.item.price;
      for (final mod in cartItem.selectedModifiers) {
        itemPrice += mod.price;
      }
      total += itemPrice * cartItem.quantity;
    }
    return total;
  }
}
