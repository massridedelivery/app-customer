import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:customer_app/features/home/presentation/states/home_state.dart';
import 'package:customer_app/features/profile/presentation/controllers/address_form_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _addressNameCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final String _chosenAddress = '';
  final double _lat = 13.7563;
  final double _lng = 100.5018;

  @override
  void dispose() {
    _addressNameCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Clear previous food location/address selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).setFoodLocation(
        const LatLng(13.7563, 100.5018),
        '',
      );
    });

    // Add listeners to sync values with Riverpod State Controller
    _addressNameCtrl.addListener(() {
      ref.read(addressFormControllerProvider.notifier).updateAddressName(_addressNameCtrl.text);
    });
    _contactNameCtrl.addListener(() {
      ref.read(addressFormControllerProvider.notifier).updateContactName(_contactNameCtrl.text);
    });
    _contactPhoneCtrl.addListener(() {
      ref.read(addressFormControllerProvider.notifier).updateContactPhone(_contactPhoneCtrl.text);
    });
    _noteCtrl.addListener(() {
      ref.read(addressFormControllerProvider.notifier).updateNote(_noteCtrl.text);
    });
  }

  Future<void> _selectAddressFromMap() async {
    ref.read(homeControllerProvider.notifier).startSelection(
          mode: RideSelectionMode.food,
        );
    context.push('/food-location-selection?from=add-address');
  }

  Future<void> _saveAddress(String activeAddress) async {
    final homeState = ref.read(homeControllerProvider);
    final activeLat = (homeState.foodAddress != null && homeState.foodAddress!.isNotEmpty && homeState.foodLocation != null)
        ? homeState.foodLocation!.latitude
        : _lat;
    final activeLng = (homeState.foodAddress != null && homeState.foodAddress!.isNotEmpty && homeState.foodLocation != null)
        ? homeState.foodLocation!.longitude
        : _lng;

    final success = await ref.read(addressFormControllerProvider.notifier).saveAddress(
          activeAddress: activeAddress,
          activeLat: activeLat,
          activeLng: activeLng,
        );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (!success && mounted) {
      final errorMsg = ref.read(addressFormControllerProvider).errorMessage ?? 
          AppLocalizations.of(context)!.cannotSaveAddress;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formState = ref.watch(addressFormControllerProvider);
    final homeState = ref.watch(homeControllerProvider);
    final displayAddress = (homeState.foodAddress != null && homeState.foodAddress!.isNotEmpty)
        ? homeState.foodAddress!
        : _chosenAddress;

    final isValid = formState.addressName.trim().isNotEmpty &&
        formState.contactName.trim().isNotEmpty &&
        formState.contactPhone.trim().isNotEmpty &&
        displayAddress.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.deliveryInfo,
          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address Name Section
                      _buildHeader(l10n.addressName),
                      const SizedBox(height: 8),
                      _CustomTextField(
                        controller: _addressNameCtrl,
                        hint: l10n.addressNameHint,
                      ),
                      const SizedBox(height: 20),

                      // Contact Info Section
                      _buildHeader(l10n.contactInfo),
                      const SizedBox(height: 8),
                      _CustomTextField(
                        controller: _contactNameCtrl,
                        hint: l10n.contactName,
                      ),
                      const SizedBox(height: 12),
                      _CustomTextField(
                        controller: _contactPhoneCtrl,
                        hint: l10n.phoneNumber,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Address Info Section
                      _buildHeader(l10n.addressInfo),
                      const SizedBox(height: 8),
                      _ChooseFromMapButton(
                        address: displayAddress,
                        onTap: _selectAddressFromMap,
                      ),
                      const SizedBox(height: 24),

                      // Note to Rider Section
                      _buildHeader(l10n.noteToRider, isRequired: false),
                      const SizedBox(height: 8),
                      _CustomTextField(
                        controller: _noteCtrl,
                        hint: l10n.noteToRiderHint,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Set Default Checkbox Row
                      Row(
                        children: [
                          Checkbox(
                            value: formState.isDefault,
                            onChanged: (val) {
                              ref
                                  .read(addressFormControllerProvider.notifier)
                                  .toggleDefault(val ?? false);
                            },
                            activeColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.foundationGrayscale400,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(addressFormControllerProvider.notifier)
                                  .toggleDefault(!formState.isDefault);
                            },
                            child: Text(
                              l10n.setAsDefaultAddress,
                              style: AppTypography.body1.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Save Button Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isValid && !formState.isSaving ? () => _saveAddress(displayAddress) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.foundationGrayscale200,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: formState.isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.save,
                          style: AppTypography.heading4.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, {bool isRequired = true}) {
    return RichText(
      text: TextSpan(
        text: title,
        style: AppTypography.label1.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  const _CustomTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body2.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.foundationGrayscale300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _ChooseFromMapButton extends StatelessWidget {
  final String address;
  final VoidCallback onTap;

  const _ChooseFromMapButton({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.softRedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.foundationRed200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasAddress ? address : AppLocalizations.of(context)!.chooseFromMap,
                style: AppTypography.body1.copyWith(
                  color: AppColors.foundationRed800,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
