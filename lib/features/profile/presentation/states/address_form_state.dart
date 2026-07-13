import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_form_state.freezed.dart';

@freezed
abstract class AddressFormState with _$AddressFormState {
  const factory AddressFormState({
    @Default('') String addressName,
    @Default('') String contactName,
    @Default('') String contactPhone,
    @Default('') String note,
    @Default(false) bool isDefault,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = _AddressFormState;
}
