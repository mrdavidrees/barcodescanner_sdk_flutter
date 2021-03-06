/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.scandit.barcodescanner_sdk_flutter;
import android.view.ViewGroup;
import android.widget.RadioGroup;
import android.os.Bundle;
import androidx.annotation.NonNull;
import android.view.MenuItem;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.widget.Toolbar;
import androidx.appcompat.app.AlertDialog;
import com.scandit.datacapture.barcode.capture.*;
import com.scandit.datacapture.barcode.data.Barcode;
import com.scandit.datacapture.barcode.data.Symbology;
import com.scandit.datacapture.barcode.data.SymbologyDescription;
import com.scandit.datacapture.barcode.ui.overlay.BarcodeCaptureOverlay;
import com.scandit.datacapture.core.capture.DataCaptureContext;
import com.scandit.datacapture.core.data.FrameData;
import com.scandit.datacapture.core.source.Camera;
import com.scandit.datacapture.core.source.FrameSourceState;
import com.scandit.datacapture.core.ui.DataCaptureView;
import com.scandit.datacapture.core.ui.viewfinder.RectangularViewfinder;
import com.scandit.barcodescanner_sdk_flutter.R;
import com.scandit.datacapture.core.source.FrameSourceListener;
import com.scandit.datacapture.core.source.FrameSourceState;
import com.scandit.datacapture.core.source.TorchState;
import java.util.HashSet;

public class BarcodeScanActivity extends CameraPermissionActivity implements BarcodeCaptureListener {

    private DataCaptureContext dataCaptureContext;
    private BarcodeCapture barcodeCapture;
    private Camera camera;
    private DataCaptureView dataCaptureView;

    private AlertDialog dialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        BarcodescannerSdkFlutterPlugin.instance.captureActivity = this;

        String licenseKey = getIntent().getStringExtra("licenseKey");

        // Initialize and start the barcode recognition.
        initializeAndStartBarcodeScanning(licenseKey);
    }

    private void initializeAndStartBarcodeScanning(String licenseKey) {
        // Create data capture context using your license key.
        dataCaptureContext = DataCaptureContext.forLicenseKey(licenseKey);

        // Use the default camera and set it as the frame source of the context.
        // The camera is off by default and must be turned on to start streaming frames
        // to the data
        // capture context for recognition.
        // See resumeFrameSource and pauseFrameSource below.
        camera = Camera.getDefaultCamera();
        if (camera != null) {
            // Use the settings recommended by barcode capture.
            camera.applySettings(BarcodeCapture.createRecommendedCameraSettings());
            dataCaptureContext.setFrameSource(camera);
        }

        // The barcode capturing process is configured through barcode capture settings
        // which are then applied to the barcode capture instance that manages barcode
        // recognition.
        BarcodeCaptureSettings barcodeCaptureSettings = new BarcodeCaptureSettings();

        // The settings instance initially has all types of barcodes (symbologies)
        // disabled.
        // For the purpose of this sample we enable a very generous set of symbologies.
        // In your own app ensure that you only enable the symbologies that your app
        // requires as
        // every additional enabled symbology has an impact on processing times.
        HashSet<Symbology> symbologies = new HashSet<>();
        // symbologies.add(Symbology.EAN13_UPCA);
        // symbologies.add(Symbology.EAN8);
        // symbologies.add(Symbology.UPCE);
        // symbologies.add(Symbology.QR);
        symbologies.add(Symbology.PDF417);
        // symbologies.add(Symbology.DATA_MATRIX);
        // symbologies.add(Symbology.CODE39);
        // symbologies.add(Symbology.CODE128);
        // symbologies.add(Symbology.INTERLEAVED_TWO_OF_FIVE);

        barcodeCaptureSettings.enableSymbologies(symbologies);

        // Some linear/1d barcode symbologies allow you to encode variable-length data.
        // By default, the Scandit Data Capture SDK only scans barcodes in a certain
        // length range.
        // If your application requires scanning of one of these symbologies, and the
        // length is
        // falling outside the default range, you may need to adjust the "active symbol
        // counts"
        // for this symbology. This is shown in the following few lines of code for one
        // of the
        // variable-length symbologies.
        // SymbologySettings symbologySettings =
        // barcodeCaptureSettings.getSymbologySettings(Symbology.CODE39);

        // HashSet<Short> activeSymbolCounts = new HashSet<>(
        // Arrays.asList(new Short[] { 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        // 20 }));

        // symbologySettings.setActiveSymbolCounts(activeSymbolCounts);

        // Create new barcode capture mode with the settings from above.
        barcodeCapture = BarcodeCapture.forDataCaptureContext(dataCaptureContext, barcodeCaptureSettings);

        // Register self as a listener to get informed whenever a new barcode got
        // recognized.
        barcodeCapture.addListener(this);

        // To visualize the on-going barcode capturing process on screen, setup a data
        // capture view
        // that renders the camera preview. The view must be connected to the data
        // capture context.
        dataCaptureView = DataCaptureView.newInstance(this, dataCaptureContext);

        // Add a barcode capture overlay to the data capture view to render the location
        // of captured
        // barcodes on top of the video preview.
        // This is optional, but recommended for better visual feedback.
        BarcodeCaptureOverlay overlay = BarcodeCaptureOverlay.newInstance(barcodeCapture, dataCaptureView);
        overlay.setViewfinder(new RectangularViewfinder());

//        setContentView(dataCaptureView);
        setContentView(R.layout.activity_flash_control);

        setSupportActionBar((Toolbar) findViewById(R.id.toolbarMain));
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setDisplayShowTitleEnabled(false);
            actionBar.setHomeButtonEnabled(true);
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        ((ViewGroup) findViewById(R.id.scanner_container)).addView(dataCaptureView);
        RadioGroup grpFlashButtons = findViewById(R.id.grpFlashButtons);
        if (camera.getDesiredTorchState() == TorchState.ON) {
            grpFlashButtons.check(R.id.btnOn);
        } else {
            grpFlashButtons.check(R.id.btnOff);
        }
        grpFlashButtons.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup radioGroup, int i) {
                if (i == R.id.btnOn) {
                    turnOnFlash();
                } else {
                    turnOffFlash();
                }
            }
        });
    }

    private void turnOnFlash() {
        camera.setDesiredTorchState(TorchState.ON);
    }

    private void turnOffFlash() {
        camera.setDesiredTorchState(TorchState.OFF);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void onPause() {
        pauseFrameSource();
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        barcodeCapture.removeListener(this);
        dataCaptureContext.removeMode(barcodeCapture);
        super.onDestroy();
    }

    private void pauseFrameSource() {
        // Switch camera off to stop streaming frames.
        // The camera is stopped asynchronously and will take some time to completely
        // turn off.
        // Until it is completely stopped, it is still possible to receive further
        // results, hence
        // it's a good idea to first disable barcode capture as well.
        barcodeCapture.setEnabled(false);
        camera.switchToDesiredState(FrameSourceState.OFF, null);
    }

    @Override
    protected void onResume() {
        super.onResume();

        // Check for camera permission and request it, if it hasn't yet been granted.
        // Once we have the permission the onCameraPermissionGranted() method will be
        // called.
        requestCameraPermission();
    }

    @Override
    public void onCameraPermissionGranted() {
        resumeFrameSource();
    }

    private void showResult(String result, String symbology) {
        BarcodescannerSdkFlutterPlugin.instance.onBarcodeScanReceiver(result, symbology);
    }

    private void resumeFrameSource() {
        dismissScannedCodesDialog();

        // Switch camera on to start streaming frames.
        // The camera is started asynchronously and will take some time to completely
        // turn on.
        barcodeCapture.setEnabled(true);
        camera.switchToDesiredState(FrameSourceState.ON, null);
    }

    private void dismissScannedCodesDialog() {
        if (dialog != null) {
            dialog.dismiss();
            dialog = null;
        }
    }

    @Override
    public void onBarcodeScanned(final @NonNull BarcodeCapture barcodeCapture, @NonNull BarcodeCaptureSession session,
            @NonNull FrameData frameData) {
        if (session.getNewlyRecognizedBarcodes().isEmpty())
            return;

        Barcode barcode = session.getNewlyRecognizedBarcodes().get(0);

        // Stop recognizing barcodes for as long as we are displaying the result. There
        // won't be any new results until
        // the capture mode is enabled again. Note that disabling the capture mode does
        // not stop the camera, the camera
        // continues to stream frames until it is turned off.
        barcodeCapture.setEnabled(false);

        // If you are not disabling barcode capture here and want to continue scanning,
        // consider
        // setting the codeDuplicateFilter when creating the barcode capture settings to
        // around 500
        // or even -1 if you do not want codes to be scanned more than once.

        // Get the human readable name of the symbology and assemble the result to be
        // shown.
        final String symbology = SymbologyDescription.create(barcode.getSymbology()).getReadableName();
        final String result = barcode.getData();

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                showResult(result, symbology);
                barcodeCapture.setEnabled(true);
            }
        });
    }

    @Override
    public void onSessionUpdated(@NonNull BarcodeCapture barcodeCapture, @NonNull BarcodeCaptureSession session,
            @NonNull FrameData data) {
    }

    @Override
    public void onObservationStarted(@NonNull BarcodeCapture barcodeCapture) {
    }

    @Override
    public void onObservationStopped(@NonNull BarcodeCapture barcodeCapture) {
    }
}