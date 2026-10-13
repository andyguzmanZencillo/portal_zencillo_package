package com.example.portal;

/** Pure validation shared by the bridge and native contract checks. */
public final class SdkPaymentPolicy {
    private SdkPaymentPolicy() {}

    public static boolean validAmount(double amount) {
        return !Double.isNaN(amount) && !Double.isInfinite(amount) && amount > 0;
    }

    public static boolean approved(String code, String transactionId, String authorization) {
        return "00".equals(code) && transactionId != null && !transactionId.trim().isEmpty()
                && authorization != null && !authorization.trim().isEmpty();
    }

    public static String maskedCard(String value) {
        if (value == null) return "";
        String digits = value.replaceAll("[^0-9]", "");
        return digits.isEmpty() ? "" : "****" + digits.substring(Math.max(0, digits.length() - 4));
    }

    public static boolean matchingReference(String requested, String returned) {
        return requested != null && !requested.isEmpty() && requested.equals(returned);
    }

    public static boolean isDop(String currency) {
        return "DOP".equals(currency) || "214".equals(currency);
    }
}
