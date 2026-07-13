import 'dart:async';
import 'package:customer_app/core/constants/app_assets.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_icons.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/controllers/place_search_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/home/presentation/widgets/place_search_widgets.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSearchScreen extends ConsumerStatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  ConsumerState<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends ConsumerState<PlaceSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropoffFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(homeControllerProvider);
      _pickupController.text =
          state.pickupAddress ?? AppLocalizations.of(context)!.currentLocation;
      _dropoffController.text = state.dropoffAddress ?? '';
      _dropoffFocusNode.requestFocus();
    });

    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus) {
        ref
            .read(homeControllerProvider.notifier)
            .startSelection(mode: RideSelectionMode.pickup);
        if (_pickupController.text.isNotEmpty) {
          _onSearchChanged(_pickupController.text);
        }
      }
    });

    _dropoffFocusNode.addListener(() {
      if (_dropoffFocusNode.hasFocus) {
        ref
            .read(homeControllerProvider.notifier)
            .startSelection(mode: RideSelectionMode.dropoff);
        if (_dropoffController.text.isNotEmpty) {
          _onSearchChanged(_dropoffController.text);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(placeSearchControllerProvider.notifier).search(query);
      }
    });
  }

  void _onSelectPlace(LatLng location, String name) {
    final mode = ref.read(homeControllerProvider).selectionMode;
    if (mode == RideSelectionMode.pickup) {
      ref
          .read(homeControllerProvider.notifier)
          .setPickupLocation(location, name);
      _dropoffFocusNode.requestFocus();
    } else {
      ref
          .read(homeControllerProvider.notifier)
          .setDropoffLocation(location, name);
      final currentState = ref.read(homeControllerProvider);
      if (currentState.pickupLocation != null) {
        context.push('/booking');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync controllers with state addresses without rebuilding the parent widget
    ref.listen(homeControllerProvider.select((s) => s.pickupAddress), (
      previous,
      next,
    ) {
      if (next != null && next != _pickupController.text) {
        _pickupController.text = next;
      }
    });

    ref.listen(homeControllerProvider.select((s) => s.dropoffAddress), (
      previous,
      next,
    ) {
      if (next != null && next != _dropoffController.text) {
        _dropoffController.text = next;
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.bookingDetails,
          style: AppTypography.heading4,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(),
              _buildTabs(),
              const SizedBox(height: 12),
              PlaceSearchMainContent(
                tabController: _tabController,
                onSelectPlace: _onSelectPlace,
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              AppIcons.asset(
                AppAssets.icLocationFill,
                color: AppColors.foundationGreen500,
                width: 24,
                height: 24,
              ),
              ...List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 2,
                  height: 2,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              AppIcons.asset(
                AppAssets.icLocationFill,
                color: AppColors.foundationRed700,
                width: 24,
                height: 24,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _buildSearchInput(
                  _pickupController,
                  _pickupFocusNode,
                  AppLocalizations.of(context)!.currentLocation,
                  RideSelectionMode.pickup,
                  isDropoff: false,
                ),
                const SizedBox(height: 12),
                _buildSearchInput(
                  _dropoffController,
                  _dropoffFocusNode,
                  AppLocalizations.of(context)!.searchDropoffHint,
                  RideSelectionMode.dropoff,
                  isDropoff: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(
    TextEditingController controller,
    FocusNode focusNode,
    String hint,
    RideSelectionMode mode, {
    bool isDropoff = false,
  }) {
    return SearchInputContainer(
      focusNode: focusNode,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: hint,
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (isDropoff) {
                ref
                    .read(homeControllerProvider.notifier)
                    .startSelection(mode: RideSelectionMode.dropoff);
                context.push('/select-dropoff');
              } else {
                ref
                    .read(homeControllerProvider.notifier)
                    .startSelection(mode: RideSelectionMode.pickup);
                context.push('/select-pickup');
              }
            },
            child: const Icon(
              Icons.map_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
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
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppTypography.label1.copyWith(
            color: isSelected ? AppColors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
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
              .startSelection(mode: RideSelectionMode.dropoff);
          context.push('/select-dropoff');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.selectOnMaps,
              style: AppTypography.label1.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
