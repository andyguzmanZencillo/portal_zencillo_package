import 'package:portal/models/portal_pay_response.dart';
import 'package:zencillo_helpers/zencillo_helpers.dart';

extension PortalFormaPagoDetalleMapper on PortalPayResponse {
  FormaPagoDetalleModel toFormaPagoDetalle({
    required int idTurno,
    required int numeroTurno,
    required int idDocument,
    required double total,
    required double taxTotal,
    required double subTotal,
    required int idFormaPago,
  }) {
    final jsonOriginalPortal = raw.trim().isNotEmpty
        ? raw.trim()
        : rawResponse.trim().isNotEmpty
            ? rawResponse.trim()
            : data.trim();

    final codigoRespuestaPortal = authResponseCode.trim().isNotEmpty
        ? authResponseCode.trim()
        : responseCode.trim();

    final secuencialPortal = transactionId.trim().isNotEmpty
        ? transactionId.trim()
        : autorizationCode.trim();

    final numeroAutorizacionPortal =
        approvalCode.trim().isNotEmpty ? approvalCode.trim() : secuencialPortal;

    final terminalPortal = terminalId.trim();

    final comercioPortal =
        merchantId.trim().isNotEmpty ? merchantId.trim() : merchantPosId.trim();

    final lotePortal = lot > 0 ? lot : numeroTurno;

    final referenciaPortal =
        referenceNumber.trim().isNotEmpty ? referenceNumber.trim() : rrn.trim();

    final reciboPortal =
        ticketNumber.trim().isNotEmpty ? ticketNumber.trim() : receipt.trim();
    final accountNo = maskedAccountIdentifier.isNotEmpty
        ? maskedAccountIdentifier
        : lastFourDigitsCard;

    final tarjetaPortal = maskedAccountIdentifier.trim().isNotEmpty
        ? maskedAccountIdentifier.trim()
        : accountNo.trim().isNotEmpty
            ? accountNo.trim()
            : lastFourDigitsCard.trim();

    final hostPortal = franchise.trim().isNotEmpty
        ? franchise.trim()
        : franchise.trim().isNotEmpty
            ? franchise.trim()
            : scheme.trim();

    final modoLecturaPortal =
        entryMode.trim().isNotEmpty ? entryMode.trim() : accountType.trim();

    final nombreTarjetaHabientePortal = hostPortal.trim();

    final montoTotalPortal = total > 0 ? total : total;

    final result = FormaPagoDetalleModel(
      idVenta: idDocument,
      idTurno: idTurno,

      identificacionRed: 'PORTAL_POS',
      codigoRespuestaActor: codigoRespuestaPortal,
      mensajeRespuesta: jsonOriginalPortal,

      secuencialTransaccion: secuencialPortal.toIntSafe(),
      numeroLote: lotePortal,

      horaTransaccion: DateTime.now().getHourWindDev(),
      fechaTransaccion: DateTime.now(),

      numeroAutorizacion: numeroAutorizacionPortal.limit(10),

      tid: terminalPortal,
      mid: comercioPortal,

      valorInteres: 0,
      mensajeImpresion: '',

      codigoBanco: codigoRespuestaPortal.toIntSafe(),
      nombreBanco: hostPortal,
      nombreGrupoTarjeta: hostPortal,

      modoLectura: modoLecturaPortal,

      nombreTarjetaHabiente: nombreTarjetaHabientePortal,

      montoFijo: '',
      identificadorAplicacion: '',
      aid: '',
      tipoCrigtograma: '',
      pin: '',
      arqc: '',

      numeroTarjetaTruncado: tarjetaPortal,
      fechaVencimientoTarjeta: expirationDate.trim().toIntSafe(),
      numeroTarjetaEncriptada:
          cardToken.trim().isNotEmpty ? cardToken.trim() : tarjetaPortal,

      impuesto: taxTotal,
      baseConImpuesto: subTotal + taxTotal,
      baseSinImpuesto: subTotal,
      montoImpuesto: taxTotal,
      montoTotal: montoTotalPortal,

      idFormaPago: idFormaPago,

      host: hostPortal,
      hostName: hostPortal,
      tipoTarjeta: hostPortal,
      tipoVenta: type > 0 ? type.toString() : '',

      numeroTarjeta: tarjetaPortal,
      loteAbierto: '1',

      nombreTH: nombreTarjetaHabientePortal,

      aprobacion: numeroAutorizacionPortal,

      idTerminal: terminalPortal,

      // Para Portal:
      // numeroReferencia = referenceNumber
      // codigoReferencia = ticketNumber
      numeroReferencia: referenciaPortal,
      codigoReferencia: reciboPortal,

      idComercio: comercioPortal,

      diferidoyQuickPayment: '',
      reservado: jsonOriginalPortal,
      archivoFirma: '',
      tvr: '',
      tsi: '',

      idCashBack: 0,
      anulada: false,
      multiplesVentas: false,
      result: true,
    );

    return result;
  }
}
