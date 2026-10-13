import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal/portal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('portal/sdk');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'initsk') return {'version': '1.0.124'};
      if (call.method == 'closesdk') {
        return {
          'lots': [
            {'lot': 1, 'closed': true, 'hostName': 'VISA', 'terminalId': 'T1'},
            {
              'lot': 2,
              'closed': false,
              'hostName': 'MASTER',
              'terminalId': 'T1'
            },
          ]
        };
      }
      return {
        'transactionId': 'trx-alpha-123',
        'clientReferenceId': 'sale-1',
        'authorizationCode': 'A12345',
        'responseCode': '00',
        'amount': 10.5,
        'currency': 'DOP',
        'maskedCard': '****1234',
        'terminalId': 'T1',
        'merchantId': 'M1',
        'ticketNumber': '00001',
        'referenceNumber': 'REF1',
        'hostName': 'VISA',
        'lot': 1,
      };
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('initialization uses a separate SDK channel and DEV by default',
      () async {
    final result = await Portal.initsk(token: 'test-only', merchantId: 1);
    expect(result.unwrap().version, '1.0.124');
    expect(calls.single.method, 'initsk');
    expect(calls.single.arguments['environment'], 'DEV');
  });
  test('invalid initialization does not reach native SDK', () async {
    expect((await Portal.initsk(token: '', merchantId: 0)).isErr(), true);
    expect(calls, isEmpty);
  });
  test('payment preserves nonnumeric transaction IDs and caller reference',
      () async {
    final result =
        await Portal.paysdk(amount: 10.5, clientReferenceId: 'sale-1');
    expect(result.unwrap().transactionId, 'trx-alpha-123');
    expect(result.unwrap().authorizationCode, 'A12345');
    expect(calls.single.arguments['clientReferenceId'], 'sale-1');
  });
  test('invalid amounts and empty references do not reach native SDK',
      () async {
    for (final value in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
          (await Portal.paysdk(amount: value, clientReferenceId: 'sale-1'))
              .isErr(),
          true);
    }
    expect(
        (await Portal.paysdk(amount: 1, clientReferenceId: ' ')).isErr(), true);
    expect(calls, isEmpty);
  });
  test('financial timeout preserves indeterminate status and reference',
      () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
          code: 'TRANSACTION_UNKNOWN',
          message: 'Reconcile',
          details: {'indeterminate': true});
    });
    final error = (await Portal.paysdk(amount: 1, clientReferenceId: 'sale-1'))
        .unwrapErr();
    expect(error.indeterminate, true);
    expect(error.clientReferenceId, 'sale-1');
  });
  test('malformed financial result requires reconciliation', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(
        (await Portal.paysdk(amount: 1, clientReferenceId: 'sale-1'))
            .unwrapErr()
            .indeterminate,
        true);
  });
  test('partial settlement exposes both outcomes and is not allClosed',
      () async {
    final response = (await Portal.closesdk()).unwrap();
    expect(response.lots.length, 2);
    expect(response.allClosed, false);
  });
  test('empty settlement is distinguishable from partial settlement', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => {'lots': []});
    final response = (await Portal.closesdk()).unwrap();
    expect(response.isEmpty, true);
  });
  test('missing platform returns an explicit unsupported failure', () async {
    messenger.setMockMethodCallHandler(
        channel, (_) async => throw MissingPluginException());
    expect(
        (await Portal.initsk(token: 'test-only', merchantId: 1))
            .unwrapErr()
            .code,
        'UNSUPPORTED_PLATFORM');
  });
  test('out of range timeout does not reach native SDK', () async {
    expect((await Portal.closesdk(timeout: Duration.zero)).isErr(), true);
    expect(calls, isEmpty);
  });
  test('legacy login still uses its original channel independently of SDK',
      () async {
    const legacy = MethodChannel('portal');
    MethodCall? legacyCall;
    messenger.setMockMethodCallHandler(legacy, (call) async {
      legacyCall = call;
      return {'code': 0, 'message': 'OK', 'token': 'test-only'};
    });
    try {
      final result = await Portal.login(apiKey: 'test-only', merchantId: '1');
      expect(result.unwrap().token, 'test-only');
      expect(legacyCall?.method, 'login');
      expect(calls, isEmpty);
    } finally {
      messenger.setMockMethodCallHandler(legacy, null);
    }
  });
  test('SDK progress reaches Flutter on its dedicated event stream', () async {
    const eventControl = MethodChannel('portal/sdk/events');
    messenger.setMockMethodCallHandler(eventControl, (_) async => null);
    try {
      final next = Portal.sdkEvents.first;
      await Future<void>.delayed(Duration.zero);
      await messenger.handlePlatformMessage(
          'portal/sdk/events',
          const StandardMethodCodec().encodeSuccessEnvelope({
            'state': 'reading_card',
            'clientReferenceId': 'sale-1',
          }),
          (_) {});
      final event = await next;
      expect(event.state, 'reading_card');
      expect(event.clientReferenceId, 'sale-1');
    } finally {
      messenger.setMockMethodCallHandler(eventControl, null);
    }
  });
}
