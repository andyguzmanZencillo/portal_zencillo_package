# Portal SDK paralelo al transporte app-to-app

## 1. Objetivo
Agregar `Portal.initsk`, `Portal.paysdk`, `Portal.closesdk` sin reemplazar las operaciones existentes.
## 2. Contexto de negocio
Integrar pagos Sunmi desde el proceso del capturador, conservando app-to-app para transicion.
## 3. Alcance
Android API 24+, AAR PortalSdk 1.0.124/PayLib 2.0.17, inicializacion, lectura/ejecucion DOP, cierre por lote y eventos.
## 4. Fuera de alcance
Migracion del capturador, XML/Isar, pantalla Flutter, impresion automatica, PIN propio, devoluciones, DCC extranjero, otros dispositivos y certificacion productiva.
## 5. Usuarios o roles afectados
Desarrolladores integradores; no habilitado automaticamente al operador.
## 6. Reglas de negocio
Una operacion a la vez, referencia obligatoria, no reintento automatico, IDs financieros como strings. Resultado incierto bloquea nuevos pedidos hasta reconciliacion externa. Bloqueo/referencias son por proceso, no sustituyen persistencia del host.
## 7. APIs afectadas
Canales nuevos `portal/sdk` y `portal/sdk/events`. Mantener `portal`/login/pay/close. Init devuelve version sin token. Pago devuelve datos seleccionados; cierre devuelve lotes y flags individuales.
## 8. Base de datos afectada
Ninguna migracion. SDK guarda configuracion propia; revisar proteccion SharedPreferences con proveedor. Host debe persistir intentos antes del envio.
## 9. Pantallas o componentes afectados
Solo plugin. Consumidor utiliza sdkEvents para su interfaz; SDK controla interfaz segura de PIN.
## 10. Seguridad y permisos
Credencial runtime, DEV por defecto, sin logs del puente, sin serializacion de PAN/PIN/token/expiry/tags. Revisar permisos adicionales fusionados del AAR. Sin firma ni despliegue productivo.
## 11. Validaciones
Comercio positivo, ambiente DEV/PROD, monto finito positivo, tip finito no negativo, referencia no vacia, timeout 1..300 segundos.
## 12. Manejo de errores
SdkFailure tipado con indeterminate/reference. Timeout financiero no equivale a rechazo. SDK no inicializado, busy, referencia repetida, detached, callbacks duplicados y cierre parcial visibles.
## 13. Criterios de aceptacion
- Tres metodos nuevos invocan SDK real, sin Intents.
- Metodos app-to-app no cambian sus cuerpos.
- Pago espera callbacks, no entrega exito al iniciar lectura.
- Resultado exige codigo 00, ID, autorizacion y moneda DOP; resultados no confirmados se bloquean.
- Cierre parcial expone allClosed=false.
- PAN devuelto contiene como maximo cuatro digitos.
## 14. Pruebas requeridas
flutter analyze/test; politica nativa; compilacion Android aislada sin firma. Prueba terminal DEV pendiente: inicializacion, PIN, aprobado/rechazado, perdida de red, lector cancelado, timeout y cierre parcial.
## 15. Documentacion que debe actualizarse
README, CHANGELOG, version del plugin, inventario AAR y esta especificacion.
## 16. Riesgos
Singleton SDK, callbacks/credenciales reutilizadas, payload diferente al sitio, dependencias PAX/Newpos no incluidas en AAR, PayLib previo 2.0.07, almacenamiento/debug interno del SDK. No prometer compatibilidad productiva sin pruebas y distribucion completa del proveedor.
## 17. Plan de rollback o reversa
Usar rama anterior del plugin; nuevos metodos son opt-in. No pasar operaciones inciertas al flujo app-to-app.
## 18. Checklist de entrega
Documentar resultados reales de pruebas en README; no marcar pruebas de terminal como aprobadas sin ejecutarlas.
