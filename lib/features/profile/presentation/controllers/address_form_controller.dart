import 'package:customer_app/features/home/data/datasources/place_data_source.dart';
import 'package:customer_app/features/profile/presentation/states/address_form_state.dart';
import 'package:customer_app/features/home/presentation/controllers/home_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_form_controller.g.dart';

@riverpod
class AddressFormController extends _$AddressFormController {
  @override
  AddressFormState build() {
    return const AddressFormState();
  }

  void updateAddressName(String value) {
    state = state.copyWith(addressName: value);
  }

  void updateContactName(String value) {
    state = state.copyWith(contactName: value);
  }

  void updateContactPhone(String value) {
    state = state.copyWith(contactPhone: value);
  }

  void updateNote(String value) {
    state = state.copyWith(note: value);
  }

  void toggleDefault(bool value) {
    state = state.copyWith(isDefault: value);
  }

  Future<bool> saveAddress({
    required String activeAddress,
    required double activeLat,
    required double activeLng,
  }) async {
    if (state.addressName.trim().isEmpty ||
        state.contactName.trim().isEmpty ||
        state.contactPhone.trim().isEmpty ||
        activeAddress.isEmpty) {
      state = state.copyWith(errorMessage: 'กรุณากรอกข้อมูลให้ครบถ้วน');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final noteText = 'Contact Name: ${state.contactName.trim()}\n'
          'Note: ${state.note.trim()}';

      final response = await ref.read(placeDataSourceProvider).addSavedPlace(
            name: state.addressName.trim(),
            address: activeAddress,
            lat: activeLat,
            lng: activeLng,
            note: noteText,
            isDefault: state.isDefault,
            phoneNumber: state.contactPhone.trim(),
          );

      if (state.isDefault) {
        final id = response['id']?.toString();
        if (id != null && id.isNotEmpty) {
          await ref.read(placeDataSourceProvider).setDefaultPlace(id);
        }
      }

      // Refresh home controller state to pick up the new address and default place
      await ref.read(homeControllerProvider.notifier).refreshSavedPlaces();

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
