import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:oxidized/oxidized.dart';
import 'package:portal/models/close_portal_response.dart';
import 'package:portal/models/login_portal_response.dart';
import 'package:portal/models/portal_pay_response.dart';

import 'portal_platform_interface.dart';

class MethodChannelPortal extends PortalPlatform {
  final MethodChannel _channel = const MethodChannel('portal');

  @override
  Future<Result<LoginPortalResponse, String>> login(
    String apiKey,
    String merchantId,
  ) async {
    try {
      final result = await _channel.invokeMethod('login', {
        "apiKey": apiKey,
        "merchantId": merchantId,
      });

      if (result == null) {
        return const Err('Error al iniciar sesión: respuesta nula');
      }

      if (result is Map) {
        final data = LoginPortalResponse.fromJson(
          Map<String, dynamic>.from(result),
        );
        if (data.code == 1) return Err(data.message);
        return Ok(data);
      }

      if (result is String) {
        try {
          final json = jsonDecode(result);
          if (json is Map) {
            final data = LoginPortalResponse.fromJson(
              Map<String, dynamic>.from(json),
            );
            if (data.code == 1) return Err(data.message);
            return Ok(data);
          }
          return const Err('La cadena no contiene un JSON válido de tipo Map');
        } catch (e) {
          return Err('Error al convertir la cadena a JSON: $e');
        }
      }

      return Err('Tipo de respuesta no soportado: ${result.runtimeType}');
    } catch (e) {
      return Err('Excepción inesperada en login: $e');
    }
  }

  @override
  Future<Result<PortalPayResponse, String>> pay({
    required String token,
    required double amount,
    required double tax,
    required double tip,
    required double iac,
  }) async {
    try {
      if (token.replaceAll(' ', '').isEmpty) {
        return const Err(
          'No se ha iniciado sesión en el portal, porque el token es inválido.',
        );
      }

      final result = await _channel.invokeMethod('pay', {
        "token": token,
        "amount": amount,
        "tax": tax,
        "tip": tip,
        "iac": iac,
      });

      if (result == null) {
        return const Err('Error al procesar el pago: respuesta nula');
      }

      if (result is Map) {
        final data = PortalPayResponse.fromJson(
          Map<String, dynamic>.from(result),
        );
        if (data.code == 1) return Err(data.message);
        return Ok(data);
      }

      if (result is String) {
        try {
          final json = jsonDecode(result);
          if (json is Map) {
            final data = PortalPayResponse.fromJson(
              Map<String, dynamic>.from(json),
            );
            if (data.code == 1) return Err(data.message);
            return Ok(data);
          }
          return const Err(
            'El servidor devolvió un texto que no es un JSON válido.',
          );
        } catch (e) {
          return Err('Error al decodificar respuesta del servidor: $e');
        }
      }

      return Err('Tipo de respuesta no soportado: ${result.runtimeType}');
    } catch (e) {
      return Err('Excepción inesperada en pay: $e');
    }
  }

  @override
  Future<Result<ClosePortalResponse, String>> close(String token) async {
    try {
      if (token.replaceAll(' ', '').isEmpty) {
        return const Err(
          'No se ha iniciado sesión en el portal, porque el token es inválido.',
        );
      }

      final result = await _channel.invokeMethod('close', {
        "token": token,
      });

      if (result == null) {
        return const Err('Error al cerrar la sesión: respuesta nula');
      }

      if (result is Map) {
        final data = ClosePortalResponse.fromJson(
          Map<String, dynamic>.from(result),
        );
        if (data.code == 1) return Err(data.message);
        return Ok(data);
      }

      if (result is String) {
        try {
          final json = jsonDecode(result);
          if (json is Map) {
            final data = ClosePortalResponse.fromJson(
              Map<String, dynamic>.from(json),
            );
            if (data.code == 1) return Err(data.message);
            return Ok(data);
          }
          return const Err(
            'Respuesta inesperada: el servidor devolvió texto no JSON.',
          );
        } catch (e) {
          return Err('Error al convertir la respuesta del servidor: $e');
        }
      }

      return Err('Tipo de respuesta no soportado: ${result.runtimeType}');
    } catch (e) {
      return Err('Excepción inesperada en close: $e');
    }
  }
}
