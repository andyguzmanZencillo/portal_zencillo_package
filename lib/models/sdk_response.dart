import 'package:flutter/services.dart';

/// Failure reported by the SDK bridge. An indeterminate operation must be
/// reconciled with Portal before another financial request is sent.
class SdkFailure {
  const SdkFailure(this.code, this.message,
      {this.indeterminate = false, this.clientReferenceId});

  final String code;
  final String message;
  final bool indeterminate;
  final String? clientReferenceId;

  /// Maps native [PlatformException.details] (`indeterminate`, `clientReferenceId`).
  factory SdkFailure.fromPlatformException(
    PlatformException error, {
    String? fallbackReference,
  }) {
    final details = error.details;
    String? reference;
    var indeterminate = false;
    if (details is Map) {
      final map = Map<String, dynamic>.from(details);
      indeterminate = map['indeterminate'] == true;
      final fromNative = map['clientReferenceId'];
      if (fromNative is String && fromNative.isNotEmpty) {
        reference = fromNative;
      }
    }
    return SdkFailure(
      error.code,
      error.message ?? 'Error del SDK.',
      indeterminate: indeterminate,
      clientReferenceId: reference ?? fallbackReference,
    );
  }

  @override
  String toString() => indeterminate
      ? '$code: $message (conciliar antes de reintentar)'
      : '$code: $message';
}

/// Authentication and hardware initialization completed; contains no token.
class SdkInitResponse {
  const SdkInitResponse({required this.version});
  final String version;
}

/// Sanitized financial result. IDs remain strings; no legacy XML conversion.
class SdkPayResponse {
  SdkPayResponse.fromMap(Map<String, dynamic> map)
      : transactionId = map['transactionId'] as String,
        clientReferenceId = map['clientReferenceId'] as String,
        authorizationCode = map['authorizationCode'] as String,
        responseCode = map['responseCode'] as String,
        amount = (map['amount'] as num).toDouble(),
        currency = map['currency'] as String,
        maskedCard = map['maskedCard'] as String,
        terminalId = map['terminalId'] as String,
        merchantId = map['merchantId'] as String,
        ticketNumber = map['ticketNumber'] as String,
        referenceNumber = map['referenceNumber'] as String,
        hostName = map['hostName'] as String,
        lot = (map['lot'] as num?)?.toInt();

  final String transactionId;
  final String clientReferenceId;
  final String authorizationCode;
  final String responseCode;
  final double amount;
  final String currency;
  final String maskedCard;
  final String terminalId;
  final String merchantId;
  final String ticketNumber;
  final String referenceNumber;
  final String hostName;
  final int? lot;
}

/// Per-lot settlement outcome; partial closures are not a successful closure.
class SdkLotResponse {
  SdkLotResponse.fromMap(Map<String, dynamic> map)
      : lot = (map['lot'] as num).toInt(),
        closed = map['closed'] as bool,
        hostName = map['hostName'] as String,
        terminalId = map['terminalId'] as String;

  final int lot;
  final bool closed;
  final String hostName;
  final String terminalId;
}

class SdkCloseResponse {
  SdkCloseResponse.fromMap(Map<String, dynamic> map)
      : lots = List.unmodifiable((map['lots'] as List).map((lot) =>
            SdkLotResponse.fromMap(Map<String, dynamic>.from(lot as Map))));

  final List<SdkLotResponse> lots;
  bool get allClosed => lots.every((lot) => lot.closed);
  bool get isEmpty => lots.isEmpty;
}

/// Progress emitted by the native SDK, without cardholder data or credentials.
class SdkEvent {
  SdkEvent.fromMap(Map<String, dynamic> map)
      : state = map['state'] as String,
        clientReferenceId = map['clientReferenceId'] as String?,
        timestampMs = (map['timestampMs'] as num?)?.toInt(),
        operation = map['operation'] as String?,
        code = map['code'] as String?,
        message = map['message'] as String?,
        indeterminate = map['indeterminate'] == true,
        detail = _detailFromMap(map);

  final String state;
  final String? clientReferenceId;
  final int? timestampMs;
  final String? operation;
  final String? code;
  final String? message;
  final bool indeterminate;
  final Map<String, Object?> detail;

  static Map<String, Object?> _detailFromMap(Map<String, dynamic> map) {
    const known = {
      'state',
      'clientReferenceId',
      'timestampMs',
      'operation',
      'code',
      'message',
      'indeterminate',
    };
    final detail = <String, Object?>{};
    map.forEach((key, value) {
      if (!known.contains(key)) {
        detail[key] = value;
      }
    });
    return Map.unmodifiable(detail);
  }

  @override
  String toString() {
    final buffer = StringBuffer('state=$state');
    if (operation != null) buffer.write(', op=$operation');
    if (code != null) buffer.write(', code=$code');
    if (message != null) buffer.write(', msg=$message');
    if (clientReferenceId != null) {
      buffer.write(', ref=$clientReferenceId');
    }
    if (detail.isNotEmpty) buffer.write(', detail=$detail');
    return buffer.toString();
  }
}
