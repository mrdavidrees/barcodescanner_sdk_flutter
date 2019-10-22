#import "BarcodescannerSdkFlutterPlugin.h"
#import <barcodescanner_sdk_flutter/barcodescanner_sdk_flutter-Swift.h>

@implementation BarcodescannerSdkFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [BarcodeScannerPlugin registerWithRegistrar:registrar];
}

@end
