package com.example.portal

import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.example.portal.models.ModelPay
import com.example.portal.models.ResponsePay
import org.json.JSONObject

/** PortalPlugin */
class PortalPlugin : FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null
    private var modelPay = ModelPay()

    companion object {
        private const val REQ_LOGIN = 10001
        private const val REQ_PAY = 2001
        private const val REQ_CLOSE = 3001
    }

    // --------------------------------------------------------------------------
    // 1. Register channel
    // --------------------------------------------------------------------------

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "portal")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // --------------------------------------------------------------------------
    // 2. Receive calls from Flutter
    // --------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "login" -> {
                pendingResult = result
                modelPay.sAPIKEY = call.argument<String>("apiKey")!!
                modelPay.sMerchandID = call.argument<String>("merchantId")!!
                loginPortal()
            }

            "pay" -> {
                pendingResult = result
                modelPay.sTokenPay = call.argument<String>("token")!!
                modelPay.rAmount = call.argument<Double>("amount")!!
                modelPay.rTax = call.argument<Double>("tax")!!
                modelPay.rTIP = call.argument<Double>("tip")!!
                modelPay.rIAC = call.argument<Double>("iac")!!
                sendPayment(true)
            }

            "close" -> {
                pendingResult = result
                modelPay.sTokenPay = call.argument<String>("token")!!
                closePortal(true)
            }

            else -> result.notImplemented()
        }
    }

    // --------------------------------------------------------------------------
    // 3. Get Activity reference
    // --------------------------------------------------------------------------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            handleResult(requestCode, resultCode, data)
            true
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivityForConfigChanges() {}

    // --------------------------------------------------------------------------
    // 4. Portal DOM – Intents
    // --------------------------------------------------------------------------

    private fun loginPortal() {
        val intent = Intent().apply {
            action = "com.portaldom.app.LOGIN_ATTEMPT"
            setPackage("com.portaldom.app")
            putExtra(
                "login_data",
                """
                {
                    "apiKey": "${modelPay.sAPIKEY}",
                    "merchantId": "${modelPay.sMerchandID}"
                }
                """.trimIndent()
            )
        }
        activity?.startActivityForResult(intent, REQ_LOGIN)
    }

    private fun sendPayment(print: Boolean) {
        val intent = Intent().apply {
            action = "com.portaldom.app.PROCESS_SALE"
            setPackage("com.portaldom.app")
            putExtra(
                "sale_data",
                """
                {
                    "token": "${modelPay.sTokenPay}",
                    "amount": ${modelPay.rAmount},
                    "currency": "DOP",
                    "clientReferenceId": "FLUTTER-${System.currentTimeMillis()}",
                    "shouldPrint": $print
                }
                """.trimIndent()
            )
        }
        activity?.startActivityForResult(intent, REQ_PAY)
    }

    private fun closePortal(print: Boolean) {
        val intent = Intent().apply {
            action = "com.portaldom.app.CLOSE_SETTLEMENTS"
            setPackage("com.portaldom.app")
            putExtra(
                "settlements_data",
                """
                {
                    "token": "${modelPay.sTokenPay}",
                    "shouldPrint": $print
                }
                """.trimIndent()
            )
        }
        activity?.startActivityForResult(intent, REQ_CLOSE)
    }

    // --------------------------------------------------------------------------
    // 5. Handle Activity Results
    // --------------------------------------------------------------------------

    private fun handleResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (pendingResult == null) return

        try {
            when (requestCode) {

                REQ_LOGIN -> {
                    if (resultCode == Activity.RESULT_OK) {
                        val raw = data?.getStringExtra("process_result")
                        val json = JSONObject().apply {
                            put("code", 0)
                            put("message", "Login exitoso")
                            put("token", parseLogin(raw)["token"])
                        }
                        pendingResult?.success(json.toString())
                    } else {
                        pendingResult?.success(
                            JSONObject().apply {
                                put("code", 1)
                                put("message", "Proceso de login cancelado")
                            }.toString()
                        )
                    }
                }

                REQ_PAY -> {
                    val raw =
                        if (resultCode == Activity.RESULT_OK)
                            data?.getStringExtra("process_result")
                        else null

                    pendingResult?.success(parsePay(raw))
                }

                REQ_CLOSE -> {
                    if (resultCode == Activity.RESULT_OK) {
                        pendingResult?.success(
                            JSONObject().apply {
                                put("code", 0)
                                put("message", "CIERRE EJECUTADO")
                            }.toString()
                        )
                    } else {
                        pendingResult?.success(
                            JSONObject().apply {
                                put("code", 1)
                                put("message", "Cierre cancelado por el usuario")
                            }.toString()
                        )
                    }
                }
            }
        } catch (e: Exception) {
            pendingResult?.success(
                JSONObject().apply {
                    put("code", 1)
                    put("message", "Error inesperado: ${e.message}")
                }.toString()
            )
        }

        pendingResult = null
    }

    // --------------------------------------------------------------------------
    // 6. Parse JSON responses from Portal DOM
    // --------------------------------------------------------------------------

    private fun parseLogin(raw: String?): Map<String, Any?> {
        val json = JSONObject(raw ?: "{}")
        val data = json.optJSONObject("Data")
        return mapOf(
            "token" to data?.optString("AccessToken")
        )
    }

    private fun parsePay(raw: String?): String {
        return try {
            if (raw == null) {
                return JSONObject().apply {
                    put("code", 1)
                    put("message", "Respuesta vacía del proceso de pago")
                    put("raw", JSONObject.NULL)
                }.toString()
            }

            val obj = JSONObject(raw)
            val response = ResponsePay(modelPay)

            // Guardamos el JSON original completo tal como llega desde Portal DOM
            response.rawResponse = raw

            val error = obj.optBoolean("Error", true)
            val portalCode = obj.optString("Code", "")
            val portalMessage = obj.optString("Message", "")

            response.responseCode = portalCode
            response.message = portalMessage

            if (error) {
                return JSONObject().apply {
                    put("code", 1)
                    put("message", portalMessage.ifEmpty { "Error en proceso de pago" })
                    put("portalCode", portalCode)

                    // JSON original tal como llegó
                    put("raw", raw)
                }.toString()
            }

            val data = obj.optJSONObject("Data")

            if (data == null) {
                return JSONObject().apply {
                    put("code", 1)
                    put("message", "La respuesta no contiene Data")
                    put("portalCode", portalCode)

                    // JSON original tal como llegó
                    put("raw", raw)
                }.toString()
            }

            response.apply {
                // ------------------------------------------------------------------
                // Campos originales de Data
                // ------------------------------------------------------------------

                messageName = data.optString("messageName", "")
                messageType = data.optString("messageType", "")
                subMessageType = data.optString("subMessageType", "")
                globalStatus = data.optInt("globalStatus", 0)
                messageId = data.optString("messageId", "")
                grandTotal = data.optDouble("grandTotal", 0.0)
                tipsAmount = data.optDouble("tipsAmount", 0.0)
                scheme = data.optString("scheme", "")
                localTimestamp = data.optString("localTimestamp", "")
                entryMode = data.optString("entryMode", "")
                referenceNumber = data.optString("referenceNumber", "")
                authResponseCode = data.optString("authResponseCode", "")
                cardToken = data.optString("cardToken", "")
                maskedAccountIdentifier = data.optString("maskedAccountIdentifier", "")
                expirationDate = data.optString("expirationDate", "")
                traceAuditNo = data.optString("traceAuditNo", "")
                transactionId = data.optString("transactionId", "")
                ticketNumber = data.optString("ticketNumber", "")
                terminalId = data.optString("terminalId", "")
                merchantId = data.optString("merchantId", "")
                currencyCode = data.optString("currencyCode", "")
                currencySymbol = data.optString("currencySymbol", "")
                approvalCode = data.optString("approvalCode", "")
                total = data.optDouble("total", 0.0)
                type = data.optInt("type", 0)
                lot = data.optInt("lot", 0)
                isDCC = data.optString("isDCC", "")
                description = data.optString("Description", "")

                // ------------------------------------------------------------------
                // Campos compatibles con tu respuesta anterior
                // ------------------------------------------------------------------

                autorizationCode = approvalCode.ifEmpty { transactionId }
                value = total.toString()
                tax = modelPay.rTax.toString()
                rrn = referenceNumber
                receipt = ticketNumber
                timeDate = localTimestamp
                responseCode = authResponseCode.ifEmpty { portalCode }
                franchise = scheme
                accountType = entryMode
                lastFourDigitsCard = maskedAccountIdentifier
                merchantPosId = merchantId

                // JSON original dentro de data
                rawResponse = raw
            }

            JSONObject().apply {
                put("code", 0)
                put("message", "Pago exitoso")
                put("data", JSONObject(response.toMap()))

                // JSON original fuera de data, tal como llegó
                put("raw", raw)
            }.toString()

        } catch (e: Exception) {
            JSONObject().apply {
                put("code", 1)
                put("message", "Error al parsear respuesta: ${e.message}")

                // Si falla el parseo, igual devolvemos lo que llegó
                put("raw", raw ?: JSONObject.NULL)
            }.toString()
        }
    }
}
