import Flutter
import UIKit
import AVFoundation

public class BarcodeScannerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var barcodeStream: FlutterEventSink?
    private var barcodeScannerViewController: UIViewController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "barcodescanner_sdk_flutter", binaryMessenger: registrar.messenger())
        let instance = BarcodeScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let eventChannel=FlutterEventChannel(name: "barcodescanner_sdk_flutter_receiver", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    /// Check for camera availability
    private var isCameraAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    private var isCameraAuthorised: Bool{
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        barcodeStream = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        barcodeStream = nil
        return nil
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let rootViewController = UIApplication.shared.delegate?.window??.rootViewController

        if call.method == "closeBarcodeScanner" {
            barcodeScannerViewController?.dismiss(animated: true) { }
        }
        else if call.method == "startBarcodeScanner" {
            let params = call.arguments as! [String: Any]
            let licenseKey = params["license"] as! String
            
            
            let scannerViewController = BarcodeScannerViewController(licenseKey: licenseKey)
            scannerViewController.delegate = self
            let nav = UINavigationController(rootViewController: scannerViewController)
            barcodeScannerViewController = nav
            
            if isCameraAvailable {
                if isCameraAuthorised {
                    rootViewController?.present(nav, animated: true, completion: nil)
                }
                else {
                    AVCaptureDevice.requestAccess(for: .video) { success in
                        DispatchQueue.main.async {
                            if success {
                                rootViewController?.present(scannerViewController, animated: true, completion: nil)
                            } else {
                                let alert = UIAlertController(title: "Action needed", message: "Please grant camera permission to use barcode scanner", preferredStyle: .alert)
                                
                                alert.addAction(UIAlertAction(title: "Grant", style: .default, handler: { action in
                                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                }))
                                
                                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
                                     result(FlutterError(code: "2", message: "Camera not available", details: nil))
                                }))
                                
                                rootViewController?.present(alert, animated: true)
                            }
                        }
                    }
                }
            } else {
                result(FlutterError(code: "1", message: "Camera not available", details: nil))
            }
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }
    
}

extension BarcodeScannerPlugin: ScanBarcodeDelegate {
    func onResultRecieved(_ result: String, _ symbology: String, completion: @escaping () -> Void) {
        barcodeStream?(result)
        completion()
    }
    
    func onCancelled() {
         barcodeScannerViewController?.dismiss(animated: true) { }
    }
}
