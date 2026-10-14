import 'dart:convert';

import 'package:oxidized/oxidized.dart';
import 'package:portal/map/map.dart';
import 'package:portal/models/close_portal_response.dart';
import 'package:portal/models/login_portal_response.dart';
import 'package:portal/models/portal_pay_response.dart';
import 'package:portal/models/sdk_response.dart';
import 'package:portal/portal_platform_interface.dart';
import 'package:portal/sdk/portal_sdk_channel.dart';
import 'package:portal/sdk/portal_sdk_diagnostics.dart';
import 'package:zencillo_helpers/zencillo_helpers.dart';

export 'models/sdk_response.dart';
export 'sdk/portal_sdk_diagnostics.dart';

class Portal {
  /// Inicia sesión en el portal (app-to-app) o inicializa el SDK Android.
  static Future<Result<LoginPortalResponse, String>> login({
    required String apiKey,
    required String merchantId,
    bool isSdk = false,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (isSdk) {
      final merchant = int.tryParse(merchantId.trim()) ?? 0;
      final result = await PortalSdkChannel.initsk(
        token: apiKey,
        merchantId: merchant,
        timeout: timeout,
      );
      if (result.isErr()) {
        return Err(result.unwrapErr().toString());
      }
      final init = result.unwrap();
      return Ok(LoginPortalResponse.fromJson({
        'code': 0,
        'message': init.version.isEmpty ? 'SDK listo' : init.version,
        'token': apiKey.trim(),
      }));
    }
    return PortalPlatform.instance.login(apiKey, merchantId);
  }

  /// Procesa un pago (app-to-app o SDK embebido).
  static Future<Result<PortalPayResponse, String>> pay({
    required String token,
    required double amount,
    required double tax,
    required double tip,
    required double iac,
    bool isSdk = false,
    String? clientReferenceId,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    if (isSdk) {
      final reference = (clientReferenceId ?? token).trim();
      if (reference.isEmpty) {
        return const Err('Referencia de venta requerida.');
      }
      final result = await PortalSdkChannel.paysdk(
        amount: amount,
        clientReferenceId: reference,
        tip: tip,
        timeout: timeout,
      );
      if (result.isErr()) {
        return Err(result.unwrapErr().toString());
      }
      return Ok(result.unwrap().toPortalPayResponse());
    }
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
    bool isSdk = false,
    String? clientReferenceId,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final result = await pay(
      token: token,
      amount: total,
      tax: taxTotal,
      tip: tip,
      iac: iac,
      isSdk: isSdk,
      clientReferenceId: clientReferenceId,
      timeout: timeout,
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

  static Future<Result<FormaPagoDetalleModel, String>> payComplete({
    required String token,
    required double total,
    required double taxTotal,
    required double subTotal,
    required double tip,
    required double iac,
    bool isSdk = false,
    String? clientReferenceId,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final result = await pay(
      token: token,
      amount: total,
      tax: taxTotal,
      tip: tip,
      iac: iac,
      isSdk: isSdk,
      clientReferenceId: clientReferenceId,
      timeout: timeout,
    );

    if (result.isErr()) {
      return Err(result.unwrapErr());
    }
    final data = result.unwrap();
    final formaPagoDetalle = data.toFormaPagoDetalle(
      idTurno: 0,
      numeroTurno: 0,
      idDocument: 0,
      total: total,
      taxTotal: taxTotal,
      subTotal: subTotal,
      idFormaPago: 0,
    );
    return Ok(formaPagoDetalle);
  }

  /// Cierre de lotes (app-to-app o settlement SDK).
  static Future<Result<ClosePortalResponse, String>> close(
    String token, {
    bool isSdk = false,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    if (isSdk) {
      final result = await PortalSdkChannel.closesdk(timeout: timeout);
      if (result.isErr()) {
        return Err(result.unwrapErr().toString());
      }
      final sdk = result.unwrap();
      final lots = sdk.lots
          .map((lot) => {
                'lot': lot.lot,
                'closed': lot.closed,
                'hostName': lot.hostName,
                'terminalId': lot.terminalId,
              })
          .toList();
      return Ok(ClosePortalResponse(
        code: 0,
        message: sdk.allClosed ? 'OK' : 'Cierre parcial',
        jsonData: jsonEncode({'lots': lots, 'allClosed': sdk.allClosed}),
      ));
    }
    return PortalPlatform.instance.close(token);
  }

  static Stream<SdkEvent> get sdkEvents => PortalSdkChannel.events;

  /// Trazas nativas + Dart para diagnóstico en campo (sin credenciales completas).
  static Stream<SdkDiagnosticEntry> get sdkDiagnostics =>
      PortalSdkDiagnostics.stream;

  Future<String?> getPlatformVersion() {
    return PortalPlatform.instance.getPlatformVersion();
  }
}
