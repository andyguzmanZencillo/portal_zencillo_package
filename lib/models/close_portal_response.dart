import 'package:zencillo_helpers/zencillo_helpers.dart';

class ClosePortalResponse {
  final int code;
  final String message;
  final String jsonData;

  ClosePortalResponse({
    required this.code,
    required this.message,
    required this.jsonData,
  });

  factory ClosePortalResponse.fromJson(Map<String, dynamic> json) {
    return ClosePortalResponse(
      code: json.getPro('code', 0),
      message: json.getPro('message', ''),
      jsonData: json.getPro('jsonData', ''),
    );
  }
  //to string
  @override
  String toString() {
    return 'ClosePortalResponse{code: $code, message: $message, jsonData: $jsonData}';
  }
}
