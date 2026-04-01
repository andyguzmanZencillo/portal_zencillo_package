import 'package:portal/extension/get_pro.dart';

class ClosePortalResponse {
  final int code;
  final String message;

  ClosePortalResponse({
    required this.code,
    required this.message,
  });

  factory ClosePortalResponse.fromJson(Map<String, dynamic> json) {
    return ClosePortalResponse(
      code: json.getPro('code', 0),
      message: json.getPro('message', ''),
    );
  }
}
