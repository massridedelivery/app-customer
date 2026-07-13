import 'package:json_annotation/json_annotation.dart';

part 'send_otp_response.g.dart';

@JsonSerializable()
class SendOtpResponse {
  final String message;
  @JsonKey(name: 'ref_id')
  final String refId;
  @JsonKey(name: 'is_registered')
  final bool isRegistered;

  SendOtpResponse({
    required this.message,
    required this.refId,
    required this.isRegistered,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$SendOtpResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendOtpResponseToJson(this);
}
