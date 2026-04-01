package com.example.portal.models

import org.json.JSONObject

class ResponsePay(var modelPay: ModelPay) {

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

    fun toJSON(): String {
        val json = JSONObject()
        json.put("message", message)
        json.put("autorizationCode", autorizationCode)
        json.put("value", value)
        json.put("tax", tax)
        json.put("receipt", receipt)
        json.put("rrn", rrn)
        json.put("terminalId", terminalId)
        json.put("timeDate", timeDate)
        json.put("responseCode", responseCode)
        json.put("franchise", franchise)
        json.put("accountType", accountType)
        json.put("quotas", quotas)
        json.put("lastFourDigitsCard", lastFourDigitsCard)
        json.put("merchantPosId", merchantPosId)

        json.put("idInvoice", modelPay.nIdInvoice)
        json.put("amountSend", modelPay.rAmount)
        json.put("taxSend", modelPay.rTax)
        json.put("isla", modelPay.nIsla)

        return json.toString()
    }

    fun toMap(): Map<String, Any?> {
        return mapOf(
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

            "idInvoice" to modelPay.nIdInvoice,
            "amountSend" to modelPay.rAmount,
            "taxSend" to modelPay.rTax,
            "isla" to modelPay.nIsla
        )
    }
}
