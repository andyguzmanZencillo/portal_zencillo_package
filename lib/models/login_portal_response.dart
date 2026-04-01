import 'package:portal/extension/get_pro.dart';

class LoginPortalResponse {
  final int code;
  final String message;
  final String token;

  LoginPortalResponse.fromJson(Map<String, dynamic> json)
      : code = json.getPro('code', 0),
        message = json.getPro('message', ''),
        token = json.getPro('token', '');
}
