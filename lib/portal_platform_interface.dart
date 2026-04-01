import 'package:oxidized/oxidized.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:portal/models/close_portal_response.dart';
import 'package:portal/models/login_portal_response.dart';
import 'package:portal/models/portal_pay_response.dart';

import 'portal_method_channel.dart';

abstract class PortalPlatform extends PlatformInterface {
  /// Constructs a PortalPlatform.
  PortalPlatform() : super(token: _token);

  static final Object _token = Object();

  static PortalPlatform _instance = MethodChannelPortal();

  /// The default instance of [PortalPlatform] to use.
  ///
  /// Defaults to [MethodChannelPortal].
  static PortalPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PortalPlatform] when
  /// they register themselves.
  static set instance(PortalPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Inicia sesión en el portal
  Future<Result<LoginPortalResponse, String>> login(
    String apiKey,
    String merchantId,
  ) {
    throw UnimplementedError('login() has not been implemented.');
  }

  /// Procesa un pago en el portal
  Future<Result<PortalPayResponse, String>> pay({
    required String token,
    required double amount,
    required double tax,
    required double tip,
    required double iac,
  }) {
    throw UnimplementedError('pay() has not been implemented.');
  }

  /// Cierra la sesión del portal
  Future<Result<ClosePortalResponse, String>> close(String token) {
    throw UnimplementedError('close() has not been implemented.');
  }

  /// (Opcional / heredado)
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
