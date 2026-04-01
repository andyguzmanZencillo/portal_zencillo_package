import 'package:oxidized/oxidized.dart';

import 'models/close_portal_response.dart';
import 'models/login_portal_response.dart';
import 'models/portal_pay_response.dart';
import 'portal_platform_interface.dart';

class Portal {
  /// Inicia sesión en el portal
  static Future<Result<LoginPortalResponse, String>> login({
    required String apiKey,
    required String merchantId,
  }) {
    return PortalPlatform.instance.login(apiKey, merchantId);
  }

  /// Procesa un pago
  static Future<Result<PortalPayResponse, String>> pay({
    required String token,
    required double amount,
    required double tax,
    required double tip,
    required double iac,
  }) {
    return PortalPlatform.instance.pay(
      token: token,
      amount: amount,
      tax: tax,
      tip: tip,
      iac: iac,
    );
  }

  /// Cierra la sesión del portal
  static Future<Result<ClosePortalResponse, String>> close(String token) {
    return PortalPlatform.instance.close(token);
  }

  /// (Opcional) Versión de la plataforma
  Future<String?> getPlatformVersion() {
    return PortalPlatform.instance.getPlatformVersion();
  }
}
