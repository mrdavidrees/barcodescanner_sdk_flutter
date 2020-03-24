#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'barcodescanner_sdk_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Scandit barcode scanning'
  s.description      = <<-DESC
  Scandit barcode scanning on both Android and iOS.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.resources = ['Assets/flash_icon.png']

  s.dependency 'Flutter'
  s.dependency 'ScanditBarcodeCapture'

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'
end

