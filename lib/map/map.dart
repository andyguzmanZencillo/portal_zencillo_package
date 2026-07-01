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

    final numeroAutorizacionPortal = approvalCode.trim().isNotEmpty
        ? approvalCode.trim()
        : transactionId.trim();

    // Terminal.
    final terminalPortal = terminalId.trim();

    // Comercio.
    final comercioPortal =
        merchantId.trim().isNotEmpty ? merchantId.trim() : merchantPosId.trim();

    final referenciaPortal =
        referenceNumber.trim().isNotEmpty ? referenceNumber.trim() : rrn.trim();

    final reciboPortal =
        ticketNumber.trim().isNotEmpty ? ticketNumber.trim() : receipt.trim();

    final tarjetaPortal = maskedAccountIdentifier.trim().isNotEmpty
        ? maskedAccountIdentifier.trim()
        : lastFourDigitsCard.trim();

    final hostPortal =
        scheme.trim().isNotEmpty ? scheme.trim() : franchise.trim();

    // Modo de lectura.
    final modoLecturaPortal =
        entryMode.trim().isNotEmpty ? entryMode.trim() : accountType.trim();

    final nombreTarjetaHabientePortal = hostPortal;

    final montoTotalPortal = this.total > 0 ? this.total : total;

    final secuencialPortal = traceAuditNo.trim().isNotEmpty
        ? traceAuditNo.toIntSafe()
        : reciboPortal.toIntSafe();

    final numeroLotePortal = lot;

    final tarjetaEncriptadaPortal =
        cardToken.trim().isNotEmpty ? cardToken.trim() : tarjetaPortal;

    final result = FormaPagoDetalleModel(
      idVenta: idDocument,
      idTurno: idTurno,

      identificacionRed: 'PORTAL_POS',

      codigoRespuestaActor: codigoRespuestaPortal,

      mensajeRespuesta: jsonOriginalPortal,

      secuencialTransaccion: secuencialPortal,

      numeroLote: numeroLotePortal,

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
      numeroTarjetaEncriptada: tarjetaEncriptadaPortal,

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

      // También guardamos el JSON completo aquí por respaldo.
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
