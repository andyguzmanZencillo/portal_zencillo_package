import 'package:portal/extension/get_pro.dart';

class PortalPayResponse {
  final int code;
  final String message;

  // --------------------------------------------------------------------------
  // Campos usados actualmente por tu sistema
  // --------------------------------------------------------------------------

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

  // --------------------------------------------------------------------------
  // Datos enviados desde POS / Flutter
  // --------------------------------------------------------------------------

  final int idInvoice;
  final double amountSend;
  final double taxSend;
  final double tipSend;
  final double iacSend;
  final int isla;

  // --------------------------------------------------------------------------
  // Campos originales de Data recibidos desde Portal DOM
  // --------------------------------------------------------------------------

  final String messageName;
  final String messageType;
  final String subMessageType;
  final int globalStatus;
  final String messageId;
  final double grandTotal;
  final double tipsAmount;
  final String scheme;
  final String localTimestamp;
  final String entryMode;
  final String referenceNumber;
  final String authResponseCode;
  final String cardToken;
  final String maskedAccountIdentifier;
  final String expirationDate;
  final String traceAuditNo;
  final String transactionId;
  final String ticketNumber;
  final String merchantId;
  final String currencyCode;
  final String currencySymbol;
  final String approvalCode;
  final double total;
  final int type;
  final int lot;
  final String isDCC;
  final String description;

  // --------------------------------------------------------------------------
  // JSON original
  // --------------------------------------------------------------------------

  /// Data ya procesada convertida a texto.
  final String data;

  /// JSON original fuera de data.
  final String raw;

  /// JSON original dentro de data.
  final String rawResponse;

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
    required this.idInvoice,
    required this.amountSend,
    required this.taxSend,
    required this.tipSend,
    required this.iacSend,
    required this.isla,
    required this.messageName,
    required this.messageType,
    required this.subMessageType,
    required this.globalStatus,
    required this.messageId,
    required this.grandTotal,
    required this.tipsAmount,
    required this.scheme,
    required this.localTimestamp,
    required this.entryMode,
    required this.referenceNumber,
    required this.authResponseCode,
    required this.cardToken,
    required this.maskedAccountIdentifier,
    required this.expirationDate,
    required this.traceAuditNo,
    required this.transactionId,
    required this.ticketNumber,
    required this.merchantId,
    required this.currencyCode,
    required this.currencySymbol,
    required this.approvalCode,
    required this.total,
    required this.type,
    required this.lot,
    required this.isDCC,
    required this.description,
    required this.data,
    required this.raw,
    required this.rawResponse,
  });

  factory PortalPayResponse.fromJson(Map<String, dynamic> json) {
    final data = json.getPro('data', <String, dynamic>{});

    return PortalPayResponse(
      code: json.getPro('code', 0),
      message: json.getPro('message', ''),

      // ----------------------------------------------------------------------
      // Campos usados actualmente por tu sistema
      // ----------------------------------------------------------------------

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

      // ----------------------------------------------------------------------
      // Datos enviados desde POS / Flutter
      // ----------------------------------------------------------------------

      idInvoice: data.getPro('idInvoice', 0),
      amountSend: data.getPro('amountSend', 0.0),
      taxSend: data.getPro('taxSend', 0.0),
      tipSend: data.getPro('tipSend', 0.0),
      iacSend: data.getPro('iacSend', 0.0),
      isla: data.getPro('isla', 0),

      // ----------------------------------------------------------------------
      // Campos originales de Data recibidos desde Portal DOM
      // ----------------------------------------------------------------------

      messageName: data.getPro('messageName', ''),
      messageType: data.getPro('messageType', ''),
      subMessageType: data.getPro('subMessageType', ''),
      globalStatus: data.getPro('globalStatus', 0),
      messageId: data.getPro('messageId', ''),
      grandTotal: data.getPro('grandTotal', 0.0),
      tipsAmount: data.getPro('tipsAmount', 0.0),
      scheme: data.getPro('scheme', ''),
      localTimestamp: data.getPro('localTimestamp', ''),
      entryMode: data.getPro('entryMode', ''),
      referenceNumber: data.getPro('referenceNumber', ''),
      authResponseCode: data.getPro('authResponseCode', ''),
      cardToken: data.getPro('cardToken', ''),
      maskedAccountIdentifier: data.getPro('maskedAccountIdentifier', ''),
      expirationDate: data.getPro('expirationDate', ''),
      traceAuditNo: data.getPro('traceAuditNo', ''),
      transactionId: data.getPro('transactionId', ''),
      ticketNumber: data.getPro('ticketNumber', ''),
      merchantId: data.getPro('merchantId', ''),
      currencyCode: data.getPro('currencyCode', ''),
      currencySymbol: data.getPro('currencySymbol', ''),
      approvalCode: data.getPro('approvalCode', ''),
      total: data.getPro('total', 0.0),
      type: data.getPro('type', 0),
      lot: data.getPro('lot', 0),
      isDCC: data.getPro('isDCC', ''),
      description: data.getPro('description', ''),

      // ----------------------------------------------------------------------
      // JSON original
      // ----------------------------------------------------------------------

      data: data.toString(),

      // raw viene arriba, fuera de data
      raw: json.getPro('raw', ''),

      // rawResponse viene dentro de data
      rawResponse: data.getPro('rawResponse', ''),
    );
  }

  //tostring
  @override
  String toString() {
    return 'PortalPayResponse{code: $code, message: $message, autorizationCode: $autorizationCode, value: $value, tax: $tax, receipt: $receipt, rrn: $rrn, terminalId: $terminalId, timeDate: $timeDate, responseCode: $responseCode, franchise: $franchise, accountType: $accountType, quotas: $quotas, lastFourDigitsCard: $lastFourDigitsCard, merchantPosId: $merchantPosId, idInvoice: $idInvoice, amountSend: $amountSend, taxSend: $taxSend, tipSend: $tipSend, iacSend: $iacSend, isla: $isla, messageName: $messageName, messageType: $messageType, subMessageType: $subMessageType, globalStatus: $globalStatus, messageId: $messageId, grandTotal: $grandTotal, tipsAmount: $tipsAmount, scheme: $scheme, localTimestamp: $localTimestamp, entryMode: $entryMode, referenceNumber: $referenceNumber, authResponseCode: $authResponseCode, cardToken: $cardToken, maskedAccountIdentifier: $maskedAccountIdentifier, expirationDate: $expirationDate, traceAuditNo: $traceAuditNo, transactionId: $transactionId, ticketNumber: $ticketNumber, merchantId: $merchantId, currencyCode: $currencyCode, currencySymbol: $currencySymbol, approvalCode: $approvalCode, total: $total, type: $type, lot: $lot, isDCC: $isDCC, description: $description}';
  }
}
