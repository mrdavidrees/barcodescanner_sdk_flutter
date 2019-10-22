import 'dart:async';

import 'package:flutter/services.dart';

class BarcodescannerSdkFlutter {
  static const MethodChannel _channel = const MethodChannel('barcodescanner_sdk_flutter');

  static const EventChannel _eventChannel = const EventChannel('barcodescanner_sdk_flutter_receiver');

  static Stream _onBarcodeReceiver;

  static Stream getBarcodeStreamReceiver({license: String}) {
    /// create params to be pass to plugin
    Map params = <String, dynamic>{"license": license ?? ""};

    /// Invoke method to open camera
    /// and then create event channel which will return stream
    _channel.invokeMethod('startBarcodeScanner', params);
    if (_onBarcodeReceiver == null) {
      _onBarcodeReceiver = _eventChannel.receiveBroadcastStream();
    }
    return _onBarcodeReceiver;
  }

  static void closeBarcodeScanner() {
    /// Invoke method to open camera
    /// and then create event channel which will return stream
    _channel.invokeMethod('closeBarcodeScanner');
  }
}
