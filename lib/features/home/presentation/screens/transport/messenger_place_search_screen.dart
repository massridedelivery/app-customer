import 'dart:async';

import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/app_pill_tab.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/place_search_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/home/presentation/widgets/place_search_widgets.dart';
import 'package:customer_app/features/trips/domain/models/history_order.dart';
import 'package:customer_app/features/trips/presentation/controllers/trips_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Search-first location picker for the messenger booking flow, mirroring the
/// ride "จองรถ" experience (place autocomplete + recent/saved tabs) instead of
/// forcing a pin-drop on the map.
///
/// The field it fills — pickup vs dropoff — is read from the active
/// [RideSelectionMode] set by the caller (`pickup` → จุดรับ,
/// `messengerDropoff` → จุดส่ง), so the same screen serves both taps on the
/// messenger booking card. Selecting a place writes it back into the shared
/// HomeState (the messenger booking screen reads pickup/dropoff from there) and
/// pops. "เลือกบนแผนที่" hands off to the existing map screens for a fine pin.
class MessengerPlaceSearchScreen extends ConsumerStatefulWidget {
  const MessengerPlaceSearchScreen({super.key});

  @override
  ConsumerState<MessengerPlaceSearchScreen> createState() =>
      _MessengerPlaceSearchScreenState();
}

class _MessengerPlaceSearchScreenState
    extends ConsumerState<MessengerPlaceSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  bool _isDropoff = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final home = ref.read(homeControllerProvider);
      _isDropoff =
          home.selectionMode == RideSelectionMode.messengerDropoff;
      final current = _isDropoff ? home.dropoffAddress : home.pickupAddress;
      if (current != null && current.isNotEmpty) {
        _searchController.text = current;
      }
      _focusNode.requestFocus();
      // Start from a clean slate so a previous session's predictions don't
      // linger over the recent/saved tabs.
      ref.read(placeSearchControllerProvider.notifier).clear();

      // Warm messenger history so the "ล่าสุด" tab has real destinations to
      // offer (it falls back to frequent places when there's none yet).
      final trips = ref.read(tripsControllerProvider);
      if (trips.historyOrders.isEmpty && !trips.isHistoryLoading) {
        ref
            .read(tripsControllerProvider.notifier)
            .fetchHistoryOrders(type: HistoryType.messenger);
      }
      setState(() {}); // reflect _isDropoff in the title/hint/pin
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      ref.read(placeSearchControllerProvider.notifier).clear();
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(placeSearchControllerProvider.notifier).search(query);
      }
    });
  }

  void _onSelectPlace(LatLng location, String name) {
    final notifier = ref.read(homeControllerProvider.notifier);
    if (_isDropoff) {
      notifier.setDropoffLocation(location, name);
    } else {
      notifier.setPickupLocation(location, name);
    }
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isDropoff ? 'เลือกจุดส่งพัสดุ' : 'เลือกจุดรับพัสดุ',
          style: AppTypography.heading4,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/main');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchInput(),
            _buildTabs(l10n),
            const SizedBox(height: 12),
            PlaceSearchMainContent(
              tabController: _tabController,
              onSelectPlace: _onSelectPlace,
            ),
            _buildBottomAction(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SearchInputContainer(
        focusNode: _focusNode,
        child: Row(
          children: [
            AppIcons.asset(
              AppAssets.icLocationFill,
              width: 22,
              height: 22,
              color: _isDropoff
                  ? AppColors.foundationRed700
                  : AppColors.foundationGreen500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: _isDropoff
                      ? 'ค้นหาจุดส่งพัสดุ'
                      : 'ค้นหาจุดรับพัสดุ',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: AppTypography.body1.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.semanticGrayNeutralFgMidOnWhite,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabItem(0, l10n.recent),
            const SizedBox(width: 12),
            _buildTabItem(1, l10n.recommended),
            const SizedBox(width: 12),
            _buildTabItem(2, l10n.saved),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String text) {
    return AppPillTab(
      label: text,
      selected: _tabController.index == index,
      onTap: () => _tabController.animateTo(index),
    );
  }

  Widget _buildBottomAction(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.semanticGrayNeutralBorderLightgray),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Hand off to the existing pin-drop map. The active selection mode is
          // already set, so the map writes back to the right field and pops
          // straight to the messenger booking screen — replace this screen so we
          // don't leave a stale search route underneath the map.
          context.pushReplacement(
            _isDropoff ? '/select-dropoff' : '/select-pickup',
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              l10n.selectOnMaps,
              style: AppTypography.label1.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
