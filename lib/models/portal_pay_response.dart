import 'package:portal/extension/get_pro.dart';

class PortalPayResponse {
  final int code;
  final String message;
  final String autorizationCode;
  final String value;
  final String tax;
  final String receipt;
  final String rrn;
  final String terminalId;
  final String timeDate;
  final String responseCode;
  final String franchise;
  final String accountType;
  final String quotas;
  final String lastFourDigitsCard;
  final String merchantPosId;

  /// Data ya procesada que viene dentro de "data"
  final String data;

  /// JSON original en bruto que llega desde Portal DOM
  final String raw;

  PortalPayResponse({
    required this.code,
    required this.message,
    required this.autorizationCode,
    required this.value,
    required this.tax,
    required this.receipt,
    required this.rrn,
    required this.terminalId,
    required this.timeDate,
    required this.responseCode,
    required this.franchise,
    required this.accountType,
    required this.quotas,
    required this.lastFourDigitsCard,
    required this.merchantPosId,
    required this.data,
    required this.raw,
  });

  factory PortalPayResponse.fromJson(Map<String, dynamic> json) {
    final data = json.getPro('data', <String, dynamic>{});

    return PortalPayResponse(
      code: json.getPro('code', 0),
      message: json.getPro('message', ''),
      autorizationCode: data.getPro('autorizationCode', ''),
      value: data.getPro('value', ''),
      tax: data.getPro('tax', ''),
      receipt: data.getPro('receipt', ''),
      rrn: data.getPro('rrn', ''),
      terminalId: data.getPro('terminalId', ''),
      timeDate: data.getPro('timeDate', ''),
      responseCode: data.getPro('responseCode', ''),
      franchise: data.getPro('franchise', ''),
      accountType: data.getPro('accountType', ''),
      quotas: data.getPro('quotas', ''),
      lastFourDigitsCard: data.getPro('lastFourDigitsCard', ''),
      merchantPosId: data.getPro('merchantPosId', ''),

      data: data.toString(),

      // Aquí recibes el JSON original de Portal DOM
      raw: json.getPro('raw', ''),
    );
  }
}