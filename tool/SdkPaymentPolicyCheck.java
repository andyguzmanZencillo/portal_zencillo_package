import com.example.portal.SdkPaymentPolicy;

/** Run with javac/java, without loading Android or opening physical devices. */
public final class SdkPaymentPolicyCheck {
    public static void main(String[] args) {
        check(!SdkPaymentPolicy.approved("05", "trx", "auth"), "declined response");
        check(!SdkPaymentPolicy.approved("00", "", "auth"), "missing transaction");
        check(!SdkPaymentPolicy.approved("00", "trx", ""), "missing authorization");
        check(SdkPaymentPolicy.approved("00", "trx-alpha", "auth"), "approved response");
        check("****1234".equals(SdkPaymentPolicy.maskedCard("4111111111111234")), "full PAN masking");
        check("****1234".equals(SdkPaymentPolicy.maskedCard("****1234")), "already masked");
        check("".equals(SdkPaymentPolicy.maskedCard(null)), "missing card");
        check(!SdkPaymentPolicy.validAmount(Double.NaN), "NaN");
        check(!SdkPaymentPolicy.validAmount(Double.POSITIVE_INFINITY), "infinity");
        check(!SdkPaymentPolicy.validAmount(0), "zero");
        check(SdkPaymentPolicy.matchingReference("sale-1", "sale-1"), "matching reference");
        check(!SdkPaymentPolicy.matchingReference("sale-1", "sale-2"), "foreign reference");
        check(!SdkPaymentPolicy.matchingReference("sale-1", null), "missing reference");
        check(SdkPaymentPolicy.isDop("214"), "numeric DOP");
        check(!SdkPaymentPolicy.isDop("USD"), "foreign currency");
        System.out.println("15 SDK payment policy checks passed.");
    }
    private static void check(boolean condition, String name) {
        if (!condition) throw new AssertionError(name);
    }
}
