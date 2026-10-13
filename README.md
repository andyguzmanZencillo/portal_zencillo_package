# Portal Flutter: app-to-app y SDK Android

Mismos métodos de siempre: `login`, `pay`, `payFull`, `payComplete`, `close`.
Pasa `isSdk: true` para usar el SDK embebido en Android; los tipos de retorno no cambian.

```dart
import 'package:portal/portal.dart';

const useSdk = true;

final subscription = Portal.sdkEvents.listen((event) {
  // reading_card, processing_payment, ready...
});

final session = await Portal.login(
  apiKey: tokenPortal,
  merchantId: '$comercioId',
  isSdk: useSdk,
);
if (session.isOk()) {
  final pay = await Portal.pay(
    token: session.unwrap().token,
    amount: 1500,
    tax: 0,
    tip: 0,
    iac: 0,
    isSdk: useSdk,
    clientReferenceId: referenciaDeLaVenta, // SDK; si falta, usa [token]
  );
  pay.when(
    ok: (response) { /* PortalPayResponse */ },
    err: (message) { /* conciliar si el texto lo indica */ },
  );
}

final closed = await Portal.close(session.unwrap().token, isSdk: useSdk);
await subscription.cancel();
```

## Contrato

- `login`: app-to-app devuelve `token` = `AccessToken` de la app Portal (`apiKey` + `merchantId` de entrada). Con `isSdk`, `initsk` no emite sesión: `login.token` repite el `apiKey` enviado; la sesión queda en el SDK nativo.
- `pay` / `payFull` / `payComplete`: mismos parámetros; SDK usa `clientReferenceId` o, si no se pasa, el `token` como referencia de venta.
- `close`: app-to-app requiere token; SDK ignora el token y ejecuta settlement (`jsonData` incluye lotes y `allClosed`).
- Eventos: `Portal.sdkEvents` en `portal/sdk/events`.
- `SdkFailure` se expone como `Err(String)` en la API legada; mensajes indeterminados mencionan conciliar.

## Recuperacion y limites

No reintentos automaticos. Timeout/detach/error tras envio implica resultado incierto y bloquea nuevas operaciones en esta instancia. Referencias repetidas enviadas se bloquean por proceso. Cancelacion/error de lector tambien bloquea para evitar que callbacks tardios correspondan al siguiente pago. El host debe reconciliar ANTES de reiniciar o volver a cobrar; reiniciar no prueba que el pago fallo. No hay reconciliacion persistente ni idempotencia garantizada por este paquete.

SDKPortal es un singleton: cambiar comercio o repetir validacion tras fallo exige reiniciar. Repetir init exitoso con el mismo comercio devuelve estado listo; no renueva token. Renovacion/logout deben definirse con Portal. No hay pantalla nueva ni captura de PIN propia; host muestra progreso y proveedor maneja pasos seguros. Impresion y reimpresion pertenecen al consumidor y requieren voucher aprobado por proveedor. Pago e impresion son resultados separados.

## Artefactos y Android

AAR descargados del sitio del proveedor en `android/libs/maven`, con URL y SHA256 en `docs/SDK_ARTIFACTS.md`. Android API minimo 24 (tambien para consumidores de esta version); target/compile 34 en plugin. Host puede usar 35. Kotlin 1.9.24/Java 8. No copiar configuracion de firma de ejemplos.

El sitio anuncia Sunmi P2/P3 Mix; solo Sunmi se contempla aqui. Este plugin empaqueta `portal-sdk` y PayLib 2.0.17 desde `android/libs/maven`. Si la app host incluye otra PayLib Sunmi (p. ej. 2.0.07), debe quedar **una sola** version 2.0.17 en el APK. Android fusiona el manifiesto del AAR, que declara permisos amplios (Bluetooth, ubicacion, almacenamiento, QUERY_ALL_PACKAGES, etc.); revisar manifiesto final antes de distribuir.

Auditoria del binario: referencia clases externas PAX/Newpos, ademas de Sunmi/Retrofit/Gson/coroutines. La pagina solo entrega dos AAR. No se suprimen errores R8 ni se inventan dependencias PAX: confirmar distribucion completa/compatibilidad con proveedor antes de release. Dependencias comunes publicadas se declaran en Gradle.

El puente no registra respuestas ni exporta PAN, PIN, cardToken, expiry o tags. Emite una lista permitida y mascara de maximo cuatro digitos. Esto no garantiza la seguridad interna del SDK: almacenamiento en SharedPreferences/debug interno requiere auditoria del proveedor.

## Validacion

Ejecutar `flutter analyze`, `flutter test`; verificar politica nativa con `tool/SdkPaymentPolicyCheck.java`. Compilar en host Android aislado, debug, sin firmar release y sin usar dispositivos. Los checks estaticos no certifican pagos: quedan pruebas DEV de hardware/PIN, rechazado, desconexion, cierre parcial y recuperacion.

SPEC: `specs/2026-10-13-portal-sdk/SPEC.md`.
Documentacion proveedor: https://cybersource.portaldom.do/pages/sdk/index.html
