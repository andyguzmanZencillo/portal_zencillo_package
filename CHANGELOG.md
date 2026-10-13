## 1.2.5 - 2026-10-13

- Documented: app-to-app `login` devuelve `AccessToken` de Portal; con `isSdk`, `login.token` repite el `apiKey` (el SDK no emite token de sesión).

## 1.2.4 - 2026-10-13

- Changed: API simplificada — `login`, `pay`, `payFull`, `payComplete` y `close` con `isSdk`; mismos `Result` que app-to-app. Eliminados `openPortal` / resultados unificados.

## 1.2.3 - 2026-10-13

- Changed: `openPortal` usa los mismos `token` y `merchantId` para app-to-app y SDK; timeouts unificados como `timeout`.

## 1.2.2 - 2026-10-13

- Added: API unificada `Portal.openPortal`, `payPortal`, `closePortal` con flag `isSdk`; variantes `payPortalComplete` y `payPortalFull`.
- Changed: superficie publica principal en `portal.dart`; canales nativos (`portal` / `portal/sdk`) sin cambio de contrato.

## 1.2.1 - 2026-10-13

- Changed: Maven local del plugin usa URI; `initsk` solo token/comercio/timeout; fallos de init liberan el singleton.
- Added: `SdkFailure.fromPlatformException` y mapeo de `clientReferenceId` desde detalles nativos.
- Changed: plugin autocontenido (`implementation` portal-sdk + paylib 2.0.17); documentar exclusion si el host repite PayLib.

## 1.2.0 - 2026-10-13

- Added: opt-in initsk, paysdk, closesdk and sdkEvents using PortalSdk 1.0.124/PayLib 2.0.17.
- Added: sanitized SDK result models, explicit indeterminate outcomes, operation serialization, timeouts and per-lot closure status.
- Changed: Android minimum API 24, required by SDK AAR. Existing app-to-app operations remain available.
- Added: contract tests, native validation checks, integration guide and migration SPEC.
- Hardware/production certification remains pending; no changes to capturador callers.
## 0.0.1

* TODO: Describe initial release.
