package com.example.portal.models

data class ModelPay(
    var rBaseTAX: Double = 0.0,
    var rBaseIAC: Double = 0.0,
    var rBaseDev: Double = 0.0,
    var rAmount: Double = 0.0,
    var rTax: Double = 0.0,
    var rTIP: Double = 0.0,
    var rIAC: Double = 0.0,
    var nIdInvoice: Int = 0,
    var nSOCKETPOS: Int = 0,
    var nIsla: Int = 0,
    var nReceipAnullment: Int = 0,
    var sPasswordSupervisor: String = "",
    var sTextPrint: String = "",
    var sNamePackage: String = "",

    var sTokenPay: String = "",
    var sAPIKEY: String = "",
    var sMerchandID: String = ""
)
