/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import ScanditBarcodeCapture
import AVFoundation

protocol ScanBarcodeDelegate: class {
    func onResultRecieved(_ result: String, _ symbology: String, completion: @escaping () -> Void)
    func onCancelled()
}


class BarcodeScannerViewController: UIViewController {

    public weak var delegate: ScanBarcodeDelegate?
    private var context: DataCaptureContext!
    private var camera: Camera?
    private var barcodeCapture: BarcodeCapture!
    private var captureView: DataCaptureView!
    private var overlay: BarcodeCaptureOverlay!
    private var licenseKey: String
    
    private var autoLabel: UIButton?
    private var onLabel: UIButton?
    private var offLabel: UIButton?
    
    
    init(licenseKey: String) {
        self.licenseKey = licenseKey
        super.init(nibName:nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRecognition()
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(addTapped))
        navigationItem.rightBarButtonItem = cancelButton
    }
    
    @objc func addTapped() {
        delegate?.onCancelled()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Switch camera on to start streaming frames. The camera is started asynchronously and will take some time to
        // completely turn on.
        barcodeCapture.isEnabled = true
        camera?.switch(toDesiredState: .on)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Switch camera off to stop streaming frames. The camera is stopped asynchronously and will take some time to
        // completely turn off. Until it is completely stopped, it is still possible to receive further results, hence
        // it's a good idea to first disable barcode capture as well.
        barcodeCapture.isEnabled = false
        camera?.switch(toDesiredState: .off)
    }

    func setupRecognition() {
        // Create data capture context using your license key.
        context = DataCaptureContext(licenseKey: self.licenseKey)

        // Use the world-facing (back) camera and set it as the frame source of the context. The camera is off by
        // default and must be turned on to start streaming frames to the data capture context for recognition.
        // See viewWillAppear and viewDidDisappear above.
        camera = Camera.default
        context.setFrameSource(camera, completionHandler: nil)

        // Use the recommended camera settings for the BarcodeCapture mode.
        let recommenededCameraSettings = BarcodeCapture.recommendedCameraSettings()
        camera?.apply(recommenededCameraSettings)

        // The barcode capturing process is configured through barcode capture settings  
        // and are then applied to the barcode capture instance that manages barcode recognition.
        let settings = BarcodeCaptureSettings()

        // The settings instance initially has all types of barcodes (symbologies) disabled. For the purpose of this
        // sample we enable a very generous set of symbologies. In your own app ensure that you only enable the
        // symbologies that your app requires as every additional enabled symbology has an impact on processing times.
        // settings.set(symbology: .ean13UPCA, enabled: true)
        // settings.set(symbology: .ean8, enabled: true)
        // settings.set(symbology: .upce, enabled: true)
        // settings.set(symbology: .qr, enabled: true)
        settings.set(symbology: .pdf417, enabled: true)
        // settings.set(symbology: .dataMatrix, enabled: true)
        // settings.set(symbology: .code39, enabled: true)
        // settings.set(symbology: .code128, enabled: true)
        // settings.set(symbology: .interleavedTwoOfFive, enabled: true)

        // Some linear/1d barcode symbologies allow you to encode variable-length data. By default, the Scandit
        // Data Capture SDK only scans barcodes in a certain length range. If your application requires scanning of one
        // of these symbologies, and the length is falling outside the default range, you may need to adjust the "active
        // symbol counts" for this symbology. This is shown in the following few lines of code for one of the
        // variable-length symbologies.
        // let symbologySettings = settings.settings(for: .code39)
        // symbologySettings.activeSymbolCounts = Set(7...20) as Set<NSNumber>

        // Create new barcode capture mode with the settings from above.
        barcodeCapture = BarcodeCapture(context: context, settings: settings)

        // Register self as a listener to get informed whenever a new barcode got recognized.
        barcodeCapture.addListener(self)

        // To visualize the on-going barcode capturing process on screen, setup a data capture view that renders the
        // camera preview. The view must be connected to the data capture context.
        captureView = DataCaptureView(for: context, frame: view.bounds)
        captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(captureView)

        // Add a barcode capture overlay to the data capture view to render the location of captured barcodes on top of
        // the video preview. This is optional, but recommended for better visual feedback.
        overlay = BarcodeCaptureOverlay(barcodeCapture: barcodeCapture)
        overlay.viewfinder = RectangularViewfinder()
        captureView.addOverlay(overlay)
        
        addFlashIcon()
        
    }
    
    func addFlashIcon() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        
        
        let flashIcon = UIImageView(frame: .zero)
        flashIcon.translatesAutoresizingMaskIntoConstraints = false
        flashIcon.image = UIImage(named: "flash_icon.png", in: Bundle(for: BarcodeScannerViewController.self), compatibleWith: nil )?.withRenderingMode(.alwaysTemplate)
        flashIcon.contentMode = .scaleAspectFit
        flashIcon.tintColor = .white
        
        let vBar = UIView(frame: .zero)
        vBar.translatesAutoresizingMaskIntoConstraints = false
        vBar.backgroundColor = .lightGray
        
        autoLabel = UIButton(frame: .zero)
        autoLabel?.setTitle("Auto", for: .normal)
        offLabel?.setTitleColor(device.torchMode == .auto ? .white : .lightText, for: .normal)
        autoLabel?.titleLabel?.font = UIFont(name: "Montserrat-Regular", size: 14)
        autoLabel?.contentHorizontalAlignment = .left
        autoLabel?.addTarget(self, action: #selector(setTorchAuto), for: .touchUpInside)
        
        onLabel = UIButton(frame: .zero)
        onLabel?.setTitle("On", for: .normal)
        offLabel?.setTitleColor(device.torchMode == .on ? .white : .lightText, for: .normal)
        onLabel?.titleLabel?.font = UIFont(name: "Montserrat-Regular", size: 14)
        onLabel?.contentHorizontalAlignment = .center
        onLabel?.addTarget(self, action: #selector(setTorchOn), for: .touchUpInside)
        
        offLabel = UIButton(frame: .zero)
        offLabel?.setTitle("Off", for: .normal)
        offLabel?.setTitleColor(device.torchMode == .off ? .white : .lightText, for: .normal)
        offLabel?.titleLabel?.font = UIFont(name: "Montserrat-Regular", size: 14)
        offLabel?.contentHorizontalAlignment = .right
        offLabel?.addTarget(self, action: #selector(setTorchOff), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [autoLabel!, onLabel!, offLabel!])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        
        let controls = UIView()
        controls.backgroundColor = .clear
        controls.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect: UIBlurEffect
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemMaterial)
        } else {
            blurEffect = UIBlurEffect(style: .dark)
        }
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 10
        blurView.layer.masksToBounds = true
        blurView.clipsToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        controls.insertSubview(blurView, at: 0)
        controls.addSubview(stackView)
        controls.addSubview(vBar)
        controls.addSubview(flashIcon)
        
        view.addSubview(controls)
        
        let leading = NSLayoutConstraint(item: controls, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leadingMargin, multiplier: 1, constant: 16)
        leading.priority = UILayoutPriority.init(rawValue: 900)
        
        view.addConstraints([
            leading,
            NSLayoutConstraint(item: controls, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: controls, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1, constant: -16),
            NSLayoutConstraint(item: controls, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 400),
            NSLayoutConstraint(item: controls, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
            
        ])
        
        NSLayoutConstraint.activate([
            blurView.heightAnchor.constraint(equalTo: controls.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: controls.widthAnchor),
            
            flashIcon.widthAnchor.constraint(equalToConstant: 40),
            flashIcon.heightAnchor.constraint(equalToConstant: 40),
            flashIcon.centerYAnchor.constraint(equalTo: controls.centerYAnchor),
            vBar.widthAnchor.constraint(equalToConstant: 1),
            vBar.heightAnchor.constraint(equalToConstant: 30),
            vBar.centerYAnchor.constraint(equalTo: controls.centerYAnchor),
            
            flashIcon.leftAnchor.constraint(equalTo: controls.leftAnchor, constant: 26),
            vBar.leftAnchor.constraint(equalTo: flashIcon.rightAnchor, constant: 26),
            stackView.leftAnchor.constraint(equalTo: vBar.rightAnchor, constant: 26),
            
            stackView.rightAnchor.constraint(equalTo: controls.rightAnchor, constant: -26),
            stackView.centerYAnchor.constraint(equalTo: controls.centerYAnchor),
        ])
    }
    
    @objc func setTorchOn() {
        setTorch(mode: .on)
        autoLabel?.setTitleColor(.lightText, for: .normal)
        onLabel?.setTitleColor(.white, for: .normal)
        offLabel?.setTitleColor(.lightText, for: .normal)
    }
    
    @objc func setTorchOff() {
        setTorch(mode: .off)
        autoLabel?.setTitleColor(.lightText, for: .normal)
        onLabel?.setTitleColor(.lightText, for: .normal)
        offLabel?.setTitleColor(.white, for: .normal)
    }
    
    @objc func setTorchAuto() {
        setTorch(mode: .auto)
        autoLabel?.setTitleColor(.white, for: .normal)
        onLabel?.setTitleColor(.lightText, for: .normal)
        offLabel?.setTitleColor(.lightText, for: .normal)
    }

    func setTorch(mode: AVCaptureDevice.TorchMode) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if (mode == AVCaptureDevice.TorchMode.off) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else  if (mode == AVCaptureDevice.TorchMode.on) {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }
            else {
                device.torchMode = mode
            }
            
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }

}

// MARK: - BarcodeCaptureListener
extension BarcodeScannerViewController: BarcodeCaptureListener {

    func barcodeCapture(_ barcodeCapture: BarcodeCapture,
                        didScanIn session: BarcodeCaptureSession,
                        frameData: FrameData) {
        guard let barcode = session.newlyRecognizedBarcodes.first else {
            return
        }

        // Stop recognizing barcodes for as long as we are displaying the result. There won't be any new results until
        // the capture mode is enabled again. Note that disabling the capture mode does not stop the camera, the camera
        // continues to stream frames until it is turned off.
        barcodeCapture.isEnabled = false

        // If you are not disabling barcode capture here and want to continue scanning, consider setting the
        // codeDuplicateFilter when creating the barcode capture settings to around 500 or even -1 if you do not want
        // codes to be scanned more than once.
        // Get the human readable name of the symbology and assemble the result to be shown.
        let symbology = SymbologyDescription(symbology: barcode.symbology).readableName
        let result = barcode.data

        delegate?.onResultRecieved(result, symbology) { [weak self] in
            // Enable recognizing barcodes when the result is not shown anymore.
            self?.barcodeCapture.isEnabled = true
        }
    }

}
