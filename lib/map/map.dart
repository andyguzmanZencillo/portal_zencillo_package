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

    final numeroAutorizacionPortal = transactionId.trim().isNotEmpty
        ? transactionId.trim()
        : messageId.trim().isNotEmpty
            ? messageId.trim()
            : approvalCode.trim();

    final terminalPortal = terminalId.trim();

    final reciboPortal =
        ticketNumber.trim().isNotEmpty ? ticketNumber.trim() : receipt.trim();

    final tarjetaPortal = maskedAccountIdentifier.trim().isNotEmpty
        ? maskedAccountIdentifier.trim()
        : lastFourDigitsCard.trim();

    final hostPortal =
        scheme.trim().isNotEmpty ? scheme.trim() : franchise.trim();

    final comercioPortal =
        merchantId.trim().isNotEmpty ? merchantId.trim() : merchantPosId.trim();

    final fechaPortal =
        _dateFromPortalTimestamp(localTimestamp) ?? DateTime.now();

    final montoTotalPortal = this.total > 0
        ? this.total
        : grandTotal > 0
            ? grandTotal
            : total;

    return FormaPagoDetalleModel(
      idVenta: idDocument,
      idTurno: idTurno,

      identificacionRed: 'PORTAL_POS',

      // XML que funciona:
      // <CodigoRespuestaActor/>
      codigoRespuestaActor: '',

      // XML que funciona:
      // <MensajeRespuesta>{JSON}</MensajeRespuesta>
      mensajeRespuesta: jsonOriginalPortal,

      // XML que funciona:
      // <SecuencialTransaccion>949601</SecuencialTransaccion>
      // Usamos transactionId/messageId, no traceAuditNo.
      secuencialTransaccion: numeroAutorizacionPortal.toIntSafe(),

      // XML que funciona:
      // <NumeroLote>633</NumeroLote>
      // En el original funcional venía igual al documento/venta local.
      numeroLote: idDocument,

      horaTransaccion: fechaPortal.getHourWindDev(),

      // Importante: al generar XML debe salir YYYYMMDD.
      fechaTransaccion: fechaPortal,

      // XML que funciona:
      // <NumeroAutorizacion>949601</NumeroAutorizacion>
      numeroAutorizacion: numeroAutorizacionPortal.limit(10),

      // XML que funciona:
      // <TID/>
      tid: '',

      // XML que funciona:
      // <MID>000000167391001</MID>
      mid: comercioPortal,

      valorInteres: 0,
      mensajeImpresion: '',

      codigoBanco: 0,

      nombreBanco: hostPortal,
      nombreGrupoTarjeta: hostPortal,

      // XML que funciona:
      // <ModoLectura/>
      modoLectura: '',

      nombreTarjetaHabiente: hostPortal,

      montoFijo: '',
      identificadorAplicacion: '',
      aid: '',
      tipoCrigtograma: '',
      pin: '',
      arqc: '',

      // XML que funciona:
      // <NumeroTarjeta>9148</NumeroTarjeta>
      numeroTarjetaTruncado: tarjetaPortal,

      // XML que funciona:
      // <FechaVencimientoTarjeta>0</FechaVencimientoTarjeta>
      fechaVencimientoTarjeta: 0,

      // XML que funciona:
      // <NumeroTarjetaEncriptada>9148</NumeroTarjetaEncriptada>
      // NO usar cardToken porque es largo y puede truncar.
      numeroTarjetaEncriptada: tarjetaPortal,

      impuesto: taxTotal,

      // XML que funciona:
      // <BaseConImpuesto>0</BaseConImpuesto>
      baseConImpuesto: 0,

      baseSinImpuesto: subTotal,
      montoImpuesto: taxTotal,
      montoTotal: montoTotalPortal,

      idFormaPago: idFormaPago,

      host: hostPortal,
      hostName: hostPortal,
      tipoTarjeta: hostPortal,

      // XML que funciona:
      // <TipoVenta/>
      tipoVenta: '',

      numeroTarjeta: tarjetaPortal,
      loteAbierto: '1',

      // XML que funciona:
      // <NombreTH/>
      nombreTH: '',

      aprobacion: numeroAutorizacionPortal,

      // XML que funciona:
      // <IdTerminal>SDKGASNE</IdTerminal>
      idTerminal: terminalPortal,

      // XML que funciona:
      // <NumeroReferencia>000001</NumeroReferencia>
      // <CodigoReferencia>000001</CodigoReferencia>
      // Para tu JSON debe ser ticketNumber: 000003.
      numeroReferencia: reciboPortal,
      codigoReferencia: reciboPortal,

      // XML que funciona:
      // <IdComercio>SDKGASNE</IdComercio>
      // NO usar merchantId aquí.
      idComercio: terminalPortal,

      diferidoyQuickPayment: '',

      // XML que funciona:
      // <Reservado/>
      // NO guardar el JSON aquí.
      reservado: '',

      archivoFirma: '',
      tvr: '',
      tsi: '',

      idCashBack: 0,
      anulada: false,
      multiplesVentas: false,
      result: true,
    );
  }

  DateTime? _dateFromPortalTimestamp(String value) {
    final millis = int.tryParse(value.trim());
    if (millis == null || millis <= 0) return null;

    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
