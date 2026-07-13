import 'package:freezed_annotation/freezed_annotation.dart';

part 'phone_login_response.freezed.dart';
part 'phone_login_response.g.dart';

@freezed
abstract class PhoneLoginResponse with _$PhoneLoginResponse {
  const factory PhoneLoginResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'expires_in') required int expiresIn,
  }) = _PhoneLoginResponse;

  factory PhoneLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$PhoneLoginResponseFromJson(json);
}
