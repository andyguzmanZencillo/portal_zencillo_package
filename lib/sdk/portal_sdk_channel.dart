import 'package:flutter/services.dart';
import 'package:oxidized/oxidized.dart';

import '../models/sdk_response.dart';

/// Independent channel for SDK operations; app-to-app remains on `portal`.
class PortalSdkChannel {
  static const _methods = MethodChannel('portal/sdk');
  static const _events = EventChannel('portal/sdk/events');
  static final Stream<SdkEvent> events = _events.receiveBroadcastStream().map(
      (value) => SdkEvent.fromMap(Map<String, dynamic>.from(value as Map)));

  static Future<Result<SdkInitResponse, SdkFailure>> initsk({
    required String token,
    required int merchantId,
    Duration timeout = const Duration(seconds: 45),
  }) {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty || merchantId <= 0 || !_validTimeout(timeout)) {
      return Future.value(const Err(SdkFailure(
          'INVALID_ARGUMENT', 'Revise token, comercio y timeout.')));
    }
    return _invoke(
        'initsk',
        {
          'token': trimmedToken,
          'merchantId': merchantId,
          'timeoutMs': timeout.inMilliseconds,
        },
        (map) => SdkInitResponse(version: map['version'] as String? ?? ''));
  }

  static Future<Result<SdkPayResponse, SdkFailure>> paysdk({
    required double amount,
    required String clientReferenceId,
    double tip = 0,
    Duration timeout = const Duration(minutes: 2),
  }) {
    if (!amount.isFinite ||
        amount <= 0 ||
        !tip.isFinite ||
        tip < 0 ||
        clientReferenceId.trim().isEmpty ||
        !_validTimeout(timeout)) {
      return Future.value(const Err(SdkFailure(
          'INVALID_ARGUMENT', 'Revise monto, propina, referencia y timeout.')));
    }
    final reference = clientReferenceId.trim();
    return _invoke(
        'paysdk',
        {
          'amount': amount,
          'tip': tip,
          'clientReferenceId': reference,
          'timeoutMs': timeout.inMilliseconds,
        },
        SdkPayResponse.fromMap,
        reference: reference,
        financial: true);
  }

  static Future<Result<SdkCloseResponse, SdkFailure>> closesdk({
    Duration timeout = const Duration(minutes: 2),
  }) {
    if (!_validTimeout(timeout)) {
      return Future.value(
          const Err(SdkFailure('INVALID_ARGUMENT', 'Timeout fuera de rango.')));
    }
    return _invoke('closesdk', {'timeoutMs': timeout.inMilliseconds},
        SdkCloseResponse.fromMap,
        financial: true);
  }

  static bool _validTimeout(Duration timeout) =>
      timeout.inMilliseconds >= 1000 && timeout.inMilliseconds <= 300000;

  static Future<Result<T, SdkFailure>> _invoke<T>(String method,
      Map<String, dynamic> arguments, T Function(Map<String, dynamic>) parse,
      {String? reference, bool financial = false}) async {
    try {
      final value = await _methods.invokeMethod<Object?>(method, arguments);
      if (value is! Map) {
        return Err(SdkFailure('INVALID_RESPONSE', 'Respuesta SDK invalida.',
            indeterminate: financial, clientReferenceId: reference));
      }
      return Ok(parse(Map<String, dynamic>.from(value)));
    } on PlatformException catch (error) {
      return Err(
          SdkFailure.fromPlatformException(error, fallbackReference: reference));
    } on MissingPluginException {
      return const Err(SdkFailure('UNSUPPORTED_PLATFORM',
          'El SDK requiere Android y hardware compatible.'));
    } catch (_) {
      return Err(SdkFailure('INVALID_RESPONSE', 'Respuesta SDK invalida.',
          indeterminate: financial, clientReferenceId: reference));
    }
  }
}
