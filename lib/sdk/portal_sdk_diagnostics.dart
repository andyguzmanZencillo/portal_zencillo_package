import 'dart:async';

import '../models/sdk_response.dart';
import 'portal_sdk_channel.dart';

enum SdkDiagnosticSource { native, dart }

/// Entrada unificada para soporte Portal: eventos nativos + trazas Dart del puente.
class SdkDiagnosticEntry {
  const SdkDiagnosticEntry({
    required this.timestamp,
    required this.source,
    required this.phase,
    required this.message,
    this.context = const {},
  });

  factory SdkDiagnosticEntry.fromNativeEvent(SdkEvent event) {
    final context = <String, Object?>{
      ...event.detail,
      if (event.timestampMs != null) 'timestampMs': event.timestampMs,
      if (event.operation != null) 'operation': event.operation,
      if (event.code != null) 'code': event.code,
      if (event.message != null) 'message': event.message,
      if (event.indeterminate) 'indeterminate': true,
      if (event.clientReferenceId != null)
        'clientReferenceId': event.clientReferenceId,
    };
    return SdkDiagnosticEntry(
      timestamp: DateTime.now(),
      source: SdkDiagnosticSource.native,
      phase: event.state,
      message: event.message ?? event.state,
      context: context,
    );
  }

  final DateTime timestamp;
  final SdkDiagnosticSource source;
  final String phase;
  final String message;
  final Map<String, Object?> context;

  String toLogLine() {
    final iso = timestamp.toIso8601String();
    final ctx = context.isEmpty ? '' : ' | ${context.entries.map((e) => '${e.key}=${e.value}').join(', ')}';
    return '[$iso] ${source.name}/${phase}: $message$ctx';
  }
}

/// Stream broadcast: suscribirse antes o durante una operación SDK.
class PortalSdkDiagnostics {
  PortalSdkDiagnostics._();

  static final StreamController<SdkDiagnosticEntry> _controller =
      StreamController<SdkDiagnosticEntry>.broadcast();

  static StreamSubscription<SdkEvent>? _nativeSubscription;
  static var _nativeHooked = false;

  static Stream<SdkDiagnosticEntry> get stream {
    _ensureNativeHook();
    return _controller.stream;
  }

  static void _ensureNativeHook() {
    if (_nativeHooked) {
      return;
    }
    _nativeHooked = true;
    _nativeSubscription = PortalSdkChannel.events.listen(
      (event) {
        if (!_controller.isClosed) {
          _controller.add(SdkDiagnosticEntry.fromNativeEvent(event));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        logDart(
          phase: 'native_event_stream_error',
          message: error.toString(),
          context: {'stackTrace': stackTrace.toString()},
        );
      },
    );
  }

  static void logDart({
    required String phase,
    required String message,
    Map<String, Object?> context = const {},
  }) {
    _ensureNativeHook();
    if (_controller.isClosed) {
      return;
    }
    _controller.add(
      SdkDiagnosticEntry(
        timestamp: DateTime.now(),
        source: SdkDiagnosticSource.dart,
        phase: phase,
        message: message,
        context: context,
      ),
    );
  }

  /// Argumentos de method channel sin token ni PAN.
  static Map<String, Object?> sanitizeInvokeArguments(
    String method,
    Map<String, dynamic> arguments,
  ) {
    final sanitized = <String, Object?>{'method': method};
    arguments.forEach((key, value) {
      if (key == 'token') {
        final raw = value?.toString().trim() ?? '';
        sanitized['tokenLength'] = raw.length;
        sanitized['tokenHint'] = _credentialHint(raw);
        return;
      }
      sanitized[key] = value;
    });
    return sanitized;
  }

  static String _credentialHint(String value) {
    if (value.isEmpty) {
      return '(vacío)';
    }
    if (value.length <= 4) {
      return '**** (len=${value.length})';
    }
    return '****${value.substring(value.length - 4)} (len=${value.length})';
  }

  /// Ejecuta [action] y emite inicio/fin con duración (útil en apps host).
  static Future<T> trace<T>({
    required String session,
    required Future<T> Function() action,
  }) async {
    final started = DateTime.now();
    logDart(
      phase: 'session_start',
      message: 'Inicio sesión diagnóstico SDK',
      context: {'session': session},
    );
    try {
      final result = await action();
      logDart(
        phase: 'session_success',
        message: 'Sesión SDK finalizada',
        context: {
          'session': session,
          'elapsedMs': DateTime.now().difference(started).inMilliseconds,
        },
      );
      return result;
    } catch (error, stackTrace) {
      logDart(
        phase: 'session_error',
        message: error.toString(),
        context: {
          'session': session,
          'elapsedMs': DateTime.now().difference(started).inMilliseconds,
          'stackTrace': stackTrace.toString(),
        },
      );
      rethrow;
    }
  }

  /// Solo para pruebas.
  static Future<void> disposeForTest() async {
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
    _nativeHooked = false;
    await _controller.close();
  }
}
