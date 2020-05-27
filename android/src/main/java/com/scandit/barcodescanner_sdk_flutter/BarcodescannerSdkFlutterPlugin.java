package com.scandit.barcodescanner_sdk_flutter;

import java.util.Map;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.app.FlutterActivity;
// import io.flutter.plugin.common.FlutterError;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * BarcodescannerSdkFlutterPlugin
 */
public class BarcodescannerSdkFlutterPlugin implements MethodCallHandler, StreamHandler {
    public static BarcodescannerSdkFlutterPlugin instance;
    private static final String TAG = BarcodescannerSdkFlutterPlugin.class.getSimpleName();

    private Activity activity;
    private EventChannel.EventSink barcodeStream;
    public BarcodeScanActivity captureActivity;

    private BarcodescannerSdkFlutterPlugin(Activity activity) {
        this.activity = activity;
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        if (registrar.activity() == null) {
            return;
        }
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "barcodescanner_sdk_flutter");
        instance = new BarcodescannerSdkFlutterPlugin(registrar.activity());
        channel.setMethodCallHandler(instance);

        final EventChannel eventChannel = new EventChannel(registrar.messenger(), "barcodescanner_sdk_flutter_receiver");
        eventChannel.setStreamHandler(instance);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        try {
            if (call.method.equals("startBarcodeScanner")) {
                if (!(call.arguments instanceof Map)) {
                    throw new IllegalArgumentException("Plugin not passing a map as parameter: " + call.arguments);
                }
                Map<String, Object> arguments = (Map<String, Object>) call.arguments;

                startBarcodeScannerActivityView((String) arguments.get("license"));
            } else if (call.method.equals("closeBarcodeScanner")) {
                if (this.captureActivity != null) {
                    this.captureActivity.finish();
                }
            }
        } catch (Exception e) {
            // result(new FlutterError());
            Log.e(TAG, "onMethodCall: " + e.getLocalizedMessage());
        }
    }

    private void startBarcodeScannerActivityView(String licenseKey) {
        try {
            Intent intent = new Intent(activity, BarcodeScanActivity.class).putExtra("licenseKey", licenseKey);
            activity.startActivity(intent);

        } catch (Exception e) {
            Log.e(TAG, "startView: " + e.getLocalizedMessage());
        }
    }


    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        try {
            barcodeStream = eventSink;
        } catch (Exception e) {
        }
    }

    @Override
    public void onCancel(Object o) {
        try {
            barcodeStream = null;
        } catch (Exception e) {

        }
    }

    /**
     * Continuous receive barcode
     *
     * @param barcode
     */
    public void onBarcodeScanReceiver(final String barcode, final String symbology) {
        try {
            if (barcode != null && !barcode.isEmpty()) {
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        barcodeStream.success(barcode);
                    }
                });
            }
        } catch (Exception e) {
            Log.e(TAG, "onBarcodeScanReceiver: " + e.getLocalizedMessage());
        }
    }
}
