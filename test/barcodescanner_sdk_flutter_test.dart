import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barcodescanner_sdk_flutter/barcodescanner_sdk_flutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('barcodescanner_sdk_flutter');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await BarcodescannerSdkFlutter.platformVersion, '42');
  });
}
