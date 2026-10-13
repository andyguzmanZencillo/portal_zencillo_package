package com.example.portal;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import com.fideclubllc.portalsdk.core.SDKPortal;
import com.fideclubllc.portalsdk.helpers.CurrencyHelper;
import com.fideclubllc.portalsdk.helpers.EnvironmentsApp;
import com.fideclubllc.portalsdk.listeners.AuthenticationResultListener;
import com.fideclubllc.portalsdk.listeners.TransactionAsyncResultListener;
import com.fideclubllc.portalsdk.listeners.TransactionResultListener;
import com.fideclubllc.portalsdk.models.response.ReaderAsyncResponse;
import com.fideclubllc.portalsdk.models.response.TransactionResponse;
import com.fideclubllc.portalsdk.models.response.sales.OpenedLotRespose;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** SDK-only bridge. Never routes a SDK request through the legacy Intents. */
public final class PortalSdkBridge implements MethodChannel.MethodCallHandler,
        EventChannel.StreamHandler, AuthenticationResultListener,
        TransactionResultListener, TransactionAsyncResultListener {
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private final MethodChannel methods;
    private final EventChannel events;
    private volatile SDKPortal sdk;
    private Activity activity;
    private EventChannel.EventSink sink;
    private MethodChannel.Result pending;
    private String operation;
    private String reference;
    private String initializedEnvironment;
    private int initializedMerchant;
    private double amount;
    private double tip;
    private boolean ready;
    private boolean submitted;
    private boolean validationStartedHardware;
    private boolean blocked;
    private volatile boolean disposed;
    private final Set<String> submittedReferences = new HashSet<>();
    private final Set<String> completedReaderIds = new HashSet<>();
    private Runnable deadline;
    private java.util.function.BooleanSupplier legacyBusy;

    public PortalSdkBridge(BinaryMessenger messenger,
            java.util.function.BooleanSupplier legacyBusy) {
        this.legacyBusy = legacyBusy;
        methods = new MethodChannel(messenger, "portal/sdk");
        events = new EventChannel(messenger, "portal/sdk/events");
        methods.setMethodCallHandler(this);
        events.setStreamHandler(this);
    }

    public void attach(Activity value) { activity = value; }
    public boolean isBusy() { return pending != null || blocked; }

    public void detach() {
        activity = null;
        if (sdk != null) { ready = false; blocked = true; }
        if (pending != null) {
            boolean uncertain = submitted || "closesdk".equals(operation);
            blocked = true;
            fail("ACTIVITY_DETACHED", "Actividad desconectada; revise la operacion.", uncertain);
        }
    }

    public void dispose() {
        detach();
        disposed = true;
        methods.setMethodCallHandler(null);
        events.setStreamHandler(null);
        sink = null;
        worker.shutdown();
    }

    @Override public void onListen(Object arguments, EventChannel.EventSink value) { sink = value; }
    @Override public void onCancel(Object arguments) { sink = null; }

    @Override public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (!Arrays.asList("initsk", "paysdk", "closesdk").contains(call.method)) {
            result.notImplemented(); return;
        }
        if (disposed || activity == null) {
            result.error("NO_ACTIVITY", "Se requiere una actividad Android.", null); return;
        }
        if (blocked) {
            result.error("RECONCILIATION_REQUIRED", "Consulte Portal antes de otro intento.",
                    Collections.singletonMap("indeterminate", true)); return;
        }
        if (pending != null || legacyBusy.getAsBoolean()) {
            result.error("SDK_BUSY", "Hay una operacion en curso.", null); return;
        }
        Number timeout = call.argument("timeoutMs");
        if (timeout == null || timeout.longValue() < 1000 || timeout.longValue() > 300000) {
            result.error("INVALID_ARGUMENT", "Timeout fuera de rango.", null); return;
        }
        if (!"initsk".equals(call.method) && !ready) {
            result.error("SDK_NOT_INITIALIZED", "Ejecute initsk primero.", null); return;
        }
        if ("initsk".equals(call.method)) {
            String token = call.argument("token");
            Number merchant = call.argument("merchantId");
            String environment = call.argument("environment");
            if (token == null || token.trim().isEmpty() || merchant == null || merchant.intValue() <= 0
                    || !("DEV".equals(environment) || "PROD".equals(environment))) {
                result.error("INVALID_ARGUMENT", "Credenciales o ambiente invalidos.", null); return;
            }
            // SDKPortal is a process singleton. Do not silently reuse another merchant/environment.
            if (sdk != null) {
                if (ready && initializedMerchant == merchant.intValue()
                        && environment.equals(initializedEnvironment)) {
                    result.success(Collections.singletonMap("version", sdk.getTheSDKVersion()));
                } else {
                    result.error("SDK_RESTART_REQUIRED", "Reinicie para cambiar credenciales o revalidar.", null);
                }
                return;
            }
            initializedMerchant = merchant.intValue(); initializedEnvironment = environment;
            begin(call.method, result, timeout.longValue());
            Context context = activity;
            worker.execute(() -> {
                try {
                    SDKPortal.setDebugMode(false);
                    sdk = SDKPortal.validate(context, token, merchant.intValue(), EnvironmentsApp.valueOf(environment));
                    sdk.setAuthenticationResultListener(this);
                    sdk.setTransactionResultListener(this);
                    sdk.setTransactionAsyncResultListener(this);
                } catch (Exception | LinkageError e) { report("SDK_INIT_FAILED", false); }
            });
        } else if ("paysdk".equals(call.method)) {
            Number value = call.argument("amount"); Number tips = call.argument("tip");
            String clientReference = call.argument("clientReferenceId");
            if (value == null || !SdkPaymentPolicy.validAmount(value.doubleValue()) || tips == null
                    || tips.doubleValue() < 0 || !Double.isFinite(tips.doubleValue())
                    || clientReference == null || clientReference.trim().isEmpty()) {
                result.error("INVALID_ARGUMENT", "Parametros de pago invalidos.", null); return;
            }
            if (submittedReferences.contains(clientReference)) {
                result.error("DUPLICATE_REFERENCE", "Referencia ya enviada; consulte el pago existente.", null); return;
            }
            reference = clientReference; amount = value.doubleValue(); tip = tips.doubleValue(); submitted = false;
            begin(call.method, result, timeout.longValue());
            worker.execute(() -> {
                try { sdk.startReadingCard(amount); }
                catch (Exception | LinkageError e) { report("CARD_READING_FAILED", false); }
            });
        } else {
            begin(call.method, result, timeout.longValue());
            worker.execute(() -> {
                try {
                    List<OpenedLotRespose> response = sdk.transactionSettlementAll();
                    if (response == null) { report("SETTLEMENT_UNKNOWN", true); return; }
                    List<Map<String, Object>> lots = new ArrayList<>();
                    for (OpenedLotRespose lot : response) {
                        Map<String, Object> item = new HashMap<>();
                        item.put("lot", lot.getLot()); item.put("closed", Boolean.TRUE.equals(lot.isClosed));
                        item.put("hostName", text(lot.getHostName())); item.put("terminalId", text(lot.getTerminalId()));
                        lots.add(item);
                    }
                    main.post(() -> { if ("closesdk".equals(operation)) succeed(Collections.singletonMap("lots", lots)); });
                } catch (Exception | LinkageError e) { report("SETTLEMENT_UNKNOWN", true); }
            });
        }
    }

    private void begin(String name, MethodChannel.Result result, long timeout) {
        operation = name; pending = result;
        deadline = () -> {
            boolean uncertain = submitted || "closesdk".equals(operation);
            // A callback arriving after timeout must never complete a subsequent request.
            blocked = true; ready = false;
            if (!uncertain && "paysdk".equals(operation)) {
                worker.execute(() -> { try { sdk.abortReader(); } catch (Exception ignored) {} });
            }
            fail(uncertain ? "TRANSACTION_UNKNOWN" : "SDK_TIMEOUT", "Tiempo agotado; no reintente automaticamente.", uncertain);
        };
        main.postDelayed(deadline, timeout);
        emit(name + "_started");
    }

    private void emit(String state) {
        if (!disposed && sink != null) {
            Map<String, Object> event = new HashMap<>(); event.put("state", state);
            if (reference != null) event.put("clientReferenceId", reference);
            sink.success(event);
        }
    }
    private void clear() {
        if (deadline != null) main.removeCallbacks(deadline);
        pending = null; operation = null; reference = null; submitted = false;
    }
    private void succeed(Object value) {
        if (pending == null || disposed) return;
        MethodChannel.Result result = pending; emit("completed"); clear(); result.success(value);
    }
    private void fail(String code, String message, boolean uncertain) {
        if (pending == null || disposed) return;
        Map<String, Object> details = new HashMap<>(); details.put("indeterminate", uncertain);
        if (reference != null) details.put("clientReferenceId", reference);
        MethodChannel.Result result = pending; emit(uncertain ? "indeterminate" : "failed");
        clear(); result.error(code, message, details);
    }
    private void report(String code, boolean uncertain) {
        main.post(() -> {
            if (uncertain) { blocked = true; ready = false; }
            fail(code, "La operacion SDK no pudo confirmarse.", uncertain);
        });
    }
    private static String text(String value) { return value == null ? "" : value; }

    @Override public void onValidateStart() { main.post(() -> emit("validating")); }
    @Override public void onValidateEnd() {
        main.post(() -> {
            if (!"initsk".equals(operation) || validationStartedHardware) return;
            validationStartedHardware = true;
            worker.execute(() -> {
                try { if (!Boolean.TRUE.equals(sdk.sdkInit())) report("SDK_INIT_FAILED", false); }
                catch (Exception | LinkageError e) { report("SDK_INIT_FAILED", false); }
            });
        });
    }
    @Override public void onSdkInitStart() { main.post(() -> emit("hardware_initializing")); }
    @Override public void onSdkInitEnd() {
        main.post(() -> {
            if (!"initsk".equals(operation)) return;
            ready = true; emit("ready");
            succeed(Collections.singletonMap("version", sdk.getTheSDKVersion()));
        });
    }
    @Override public void onAuthFailed(String reason) {
        main.post(() -> {
            ready = false;
            if (submitted || "closesdk".equals(operation)) {
                blocked = true; fail("TRANSACTION_UNKNOWN", "Autenticacion perdida durante la operacion.", true);
            } else {
                fail("AUTH_FAILED", "No se pudo autenticar el SDK.", false);
            }
        });
    }
    @Override public void onReaderStart() { main.post(() -> emit("reading_card")); }
    @Override public void onReaderStop() { main.post(() -> emit("reader_stopped")); }
    @Override public void onReaderCancelled() {
        main.post(() -> {
            if ("paysdk".equals(operation) && !submitted) {
                blocked = true;
                fail("CARD_READING_CANCELLED", "Lectura cancelada.", false);
            }
        });
    }
    @Override public void onRemoveSavedCard() { /* No card data is exposed to Flutter. */ }
    @Override public void onReaderFinishes(ReaderAsyncResponse response) {
        main.post(() -> {
            if (!"paysdk".equals(operation) || submitted) return;
            String readerId = response == null ? null : response.getReaderTransactionId();
            if (response == null || Boolean.TRUE.equals(response.getHasError()) || readerId == null || readerId.isEmpty()) {
                blocked = true; fail("CARD_READING_FAILED", "No se pudo leer la tarjeta.", false); return;
            }
            if (!completedReaderIds.add(readerId)) return;
            submitted = true; submittedReferences.add(reference); emit("processing_payment");
            final String clientReference = reference; final double value = amount; final double tips = tip;
            worker.execute(() -> {
                try { sdk.executeSaleFromId(readerId, value, Double.toString(tips), CurrencyHelper.DOP, clientReference); }
                catch (Exception | LinkageError e) { report("TRANSACTION_UNKNOWN", true); }
            });
        });
    }
    @Override public void onTransactionSuccess(TransactionResponse response) {
        main.post(() -> {
            if (!"paysdk".equals(operation) || !submitted) return;
            if (response != null && !SdkPaymentPolicy.matchingReference(reference, response.getClientReferenceId())) {
                // A known response from an older request cannot complete the current request.
                if (submittedReferences.contains(response.getClientReferenceId())) return;
                blocked = true; ready = false;
                fail("UNCONFIRMED_RESPONSE", "La referencia del resultado no coincide.", true); return;
            }
            if (response == null || !SdkPaymentPolicy.approved(response.getResponseCode(),
                    response.getTransactionId(), response.getApprovalCode())) {
                blocked = true; ready = false;
                fail("UNCONFIRMED_RESPONSE", "El resultado requiere verificacion con Portal.", true); return;
            }
            // Whitelist output. Do not serialize the SDK object, PAN, PIN, tags, token or expiry.
            Map<String, Object> data = new HashMap<>();
            data.put("transactionId", response.getTransactionId()); data.put("clientReferenceId", reference);
            data.put("authorizationCode", response.getApprovalCode()); data.put("responseCode", response.getResponseCode());
            if (response.getTotal() == null || !SdkPaymentPolicy.validAmount(response.getTotal())
                    || !SdkPaymentPolicy.isDop(response.getCurrencyCode())) {
                blocked = true; ready = false;
                fail("UNCONFIRMED_RESPONSE", "Monto o moneda no confirmados.", true); return;
            }
            data.put("amount", response.getTotal()); data.put("currency", "DOP");
            data.put("maskedCard", SdkPaymentPolicy.maskedCard(response.getAccountNo()));
            data.put("terminalId", text(response.getTerminalId())); data.put("merchantId", text(response.getMerchantId()));
            data.put("ticketNumber", text(response.getTicketNumber())); data.put("referenceNumber", text(response.getReferenceNumber()));
            data.put("hostName", text(response.getHostName())); data.put("lot", response.getLot());
            succeed(data);
        });
    }
    @Override public void onTransactionFailure(Exception exception) {
        main.post(() -> {
            if (!"paysdk".equals(operation)) return;
            boolean uncertain = submitted; blocked = true; ready = false;
            fail(uncertain ? "TRANSACTION_UNKNOWN" : "CARD_READING_FAILED",
                    "No se confirmo el pago; revise Portal antes de reintentar.", uncertain);
        });
    }
}
