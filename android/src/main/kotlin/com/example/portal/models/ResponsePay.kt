package com.example.portal.models

import org.json.JSONObject

class ResponsePay(var modelPay: ModelPay) {

    // --------------------------------------------------------------------------
    // Campos usados actualmente por tu sistema
    // --------------------------------------------------------------------------

    var message: String = ""
    var autorizationCode: String = ""
    var value: String = ""
    var tax: String = ""
    var receipt: String = ""
    var rrn: String = ""
    var terminalId: String = ""
    var timeDate: String = ""
    var responseCode: String = ""
    var franchise: String = ""
    var accountType: String = ""
    var quotas: String = ""
    var lastFourDigitsCard: String = ""
    var merchantPosId: String = ""

    // --------------------------------------------------------------------------
    // Campos originales que llegan dentro de Data desde Portal DOM
    // --------------------------------------------------------------------------

    var messageName: String = ""
    var messageType: String = ""
    var subMessageType: String = ""
    var globalStatus: Int = 0
    var messageId: String = ""
    var grandTotal: Double = 0.0
    var tipsAmount: Double = 0.0
    var scheme: String = ""
    var localTimestamp: String = ""
    var entryMode: String = ""
    var referenceNumber: String = ""
    var authResponseCode: String = ""
    var cardToken: String = ""
    var maskedAccountIdentifier: String = ""
    var expirationDate: String = ""
    var traceAuditNo: String = ""
    var transactionId: String = ""
    var ticketNumber: String = ""
    var merchantId: String = ""
    var currencyCode: String = ""
    var currencySymbol: String = ""
    var approvalCode: String = ""
    var total: Double = 0.0
    var type: Int = 0
    var lot: Int = 0
    var isDCC: String = ""
    var description: String = ""

    // --------------------------------------------------------------------------
    // JSON original recibido desde Portal DOM, tal como llega
    // --------------------------------------------------------------------------

    var rawResponse: String = ""

    fun toJSON(): String {
        return JSONObject(toMap()).toString()
    }

    fun toMap(): Map<String, Any?> {
        return mapOf(
            // ------------------------------------------------------------------
            // Campos usados actualmente por tu sistema
            // ------------------------------------------------------------------

            "message" to message,
            "autorizationCode" to autorizationCode,
            "value" to value,
            "tax" to tax,
            "receipt" to receipt,
            "rrn" to rrn,
            "terminalId" to terminalId,
            "timeDate" to timeDate,
            "responseCode" to responseCode,
            "franchise" to franchise,
            "accountType" to accountType,
            "quotas" to quotas,
            "lastFourDigitsCard" to lastFourDigitsCard,
            "merchantPosId" to merchantPosId,

            // ------------------------------------------------------------------
            // Datos enviados desde POS / Flutter
            // ------------------------------------------------------------------

            "idInvoice" to modelPay.nIdInvoice,
            "amountSend" to modelPay.rAmount,
            "taxSend" to modelPay.rTax,
            "tipSend" to modelPay.rTIP,
            "iacSend" to modelPay.rIAC,
            "isla" to modelPay.nIsla,

            // ------------------------------------------------------------------
            // Campos originales de Data recibidos desde Portal DOM
            // ------------------------------------------------------------------

            "messageName" to messageName,
            "messageType" to messageType,
            "subMessageType" to subMessageType,
            "globalStatus" to globalStatus,
            "messageId" to messageId,
            "grandTotal" to grandTotal,
            "tipsAmount" to tipsAmount,
            "scheme" to scheme,
            "localTimestamp" to localTimestamp,
            "entryMode" to entryMode,
            "referenceNumber" to referenceNumber,
            "authResponseCode" to authResponseCode,
            "cardToken" to cardToken,
            "maskedAccountIdentifier" to maskedAccountIdentifier,
            "expirationDate" to expirationDate,
            "traceAuditNo" to traceAuditNo,
            "transactionId" to transactionId,
            "ticketNumber" to ticketNumber,
            "merchantId" to merchantId,
            "currencyCode" to currencyCode,
            "currencySymbol" to currencySymbol,
            "approvalCode" to approvalCode,
            "total" to total,
            "type" to type,
            "lot" to lot,
            "isDCC" to isDCC,
            "description" to description,

            // ------------------------------------------------------------------
            // JSON original completo dentro de data
            // ------------------------------------------------------------------

            "rawResponse" to rawResponse
        )
    }
}