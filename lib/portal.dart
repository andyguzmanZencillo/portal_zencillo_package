import 'package:oxidized/oxidized.dart';
import 'package:portal/map/map.dart';
import 'package:zencillo_helpers/zencillo_helpers.dart';

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

  static Future<Result<FormaPagoDetalleModel, String>> payFull({
    required String token,
    required int idTurno,
    required int numeroTurno,
    required int idDocument,
    required double total,
    required double taxTotal,
    required double subTotal,
    required int idFormaPago,
    required double tip,
    required double iac,
  }) async {
    final result = await PortalPlatform.instance.pay(
      token: token,
      amount: total,
      tax: taxTotal,
      tip: tip,
      iac: iac,
    );

    if (result.isErr()) {
      return Err(result.unwrapErr());
    }
    final data = result.unwrap();
    final formaPagoDetalle = data.toFormaPagoDetalle(
      idTurno: idTurno,
      numeroTurno: numeroTurno,
      idDocument: idDocument,
      total: total,
      taxTotal: taxTotal,
      subTotal: subTotal,
      idFormaPago: idFormaPago,
    );
    return Ok(formaPagoDetalle);
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
