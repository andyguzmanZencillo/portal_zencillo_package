import 'dart:convert';

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

  test('login isSdk uses SDK channel', () async {
    final result = await Portal.login(
      isSdk: true,
      apiKey: 'test-only',
      merchantId: '1',
    );
    expect(result.isOk(), true);
    expect(result.unwrap().token, 'test-only');
    expect(calls.single.method, 'initsk');
    expect(calls.single.arguments.containsKey('environment'), false);
    expect(calls.single.arguments['token'], 'test-only');
  });
  test('invalid login isSdk does not reach native', () async {
    expect(
      (await Portal.login(isSdk: true, apiKey: '', merchantId: '0')).isErr(),
      true,
    );
    expect(calls, isEmpty);
  });
  test('pay isSdk preserves IDs and caller reference', () async {
    final result = await Portal.pay(
      isSdk: true,
      token: 'sale-1',
      amount: 10.5,
      tax: 0,
      tip: 0,
      iac: 0,
    );
    expect(result.isOk(), true);
    expect(result.unwrap().transactionId, 'trx-alpha-123');
    expect(result.unwrap().approvalCode, 'A12345');
    expect(calls.single.arguments['clientReferenceId'], 'sale-1');
  });
  test('invalid pay isSdk amounts do not reach native', () async {
    for (final value in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        (await Portal.pay(
          isSdk: true,
          token: 'sale-1',
          amount: value,
          tax: 0,
          tip: 0,
          iac: 0,
        )).isErr(),
        true,
      );
    }
    expect(
      (await Portal.pay(
        isSdk: true,
        token: ' ',
        amount: 1,
        tax: 0,
        tip: 0,
        iac: 0,
      )).isErr(),
      true,
    );
    expect(calls, isEmpty);
  });
  test('financial timeout preserves indeterminate message', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
          code: 'TRANSACTION_UNKNOWN',
          message: 'Reconcile',
          details: {
            'indeterminate': true,
            'clientReferenceId': 'sale-native',
          });
    });
    final error =
        (await Portal.pay(
          isSdk: true,
          token: 'sale-1',
          amount: 1,
          tax: 0,
          tip: 0,
          iac: 0,
        )).unwrapErr();
    expect(error.contains('conciliar'), true);
  });
  test('malformed financial result requires reconciliation', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    final error = (await Portal.pay(
      isSdk: true,
      token: 'sale-1',
      amount: 1,
      tax: 0,
      tip: 0,
      iac: 0,
    )).unwrapErr();
    expect(error.contains('conciliar'), true);
  });
  test('close isSdk partial settlement encoded in jsonData', () async {
    final result = await Portal.close('', isSdk: true);
    expect(result.isOk(), true);
    final data = jsonDecode(result.unwrap().jsonData) as Map<String, dynamic>;
    expect((data['lots'] as List).length, 2);
    expect(data['allClosed'], false);
  });
  test('close isSdk empty settlement is distinguishable', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => {'lots': []});
    final result = await Portal.close('', isSdk: true);
    expect(result.isOk(), true);
    final data = jsonDecode(result.unwrap().jsonData) as Map<String, dynamic>;
    expect((data['lots'] as List).isEmpty, true);
  });
  test('missing platform returns unsupported failure', () async {
    messenger.setMockMethodCallHandler(
        channel, (_) async => throw MissingPluginException());
    final error = (await Portal.login(
      isSdk: true,
      apiKey: 'test-only',
      merchantId: '1',
    )).unwrapErr();
    expect(error.contains('UNSUPPORTED_PLATFORM'), true);
  });
  test('out of range close isSdk timeout does not reach native', () async {
    expect(
      (await Portal.close('', isSdk: true, timeout: Duration.zero)).isErr(),
      true,
    );
    expect(calls, isEmpty);
  });
  test('login app-to-app uses legacy channel independently of SDK', () async {
    const legacy = MethodChannel('portal');
    MethodCall? legacyCall;
    messenger.setMockMethodCallHandler(legacy, (call) async {
      legacyCall = call;
      return {'code': 0, 'message': 'OK', 'token': 'test-only'};
    });
    try {
      final result =
          await Portal.login(apiKey: 'test-only', merchantId: '1');
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
