import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let wifiSettingsChannel = FlutterMethodChannel(
        name: "ip_tools/wifi_settings",
        binaryMessenger: controller.binaryMessenger
      )
      wifiSettingsChannel.setMethodCallHandler { call, result in
        guard call.method == "openWifiSettings" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
          result(FlutterError(
            code: "SETTINGS_UNAVAILABLE",
            message: "App settings are unavailable",
            details: nil
          ))
          return
        }
        UIApplication.shared.open(settingsUrl, options: [:]) { didOpen in
          result(didOpen ? "app_settings" : "app_settings_unavailable")
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
