import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let apiKey = Bundle.main.object(
      forInfoDictionaryKey: "GoogleMapsAPIKey"
    ) as? String,
    !apiKey.isEmpty else {
      fatalError("Google Maps API key is missing")
    }

    GMSServices.provideAPIKey(apiKey)

    let result = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    print("[APNS] Calling registerForRemoteNotifications()")

    DispatchQueue.main.async {
      application.registerForRemoteNotifications()
    }

    return result
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map {
      String(format: "%02.2hhx", $0)
    }.joined()

    print("[APNS] Registration SUCCESS")
    print("[APNS] Token available=true")
    print("[APNS] Token length=\(token.count)")

    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[APNS] Registration FAILED")
    print("[APNS] Error=\(error.localizedDescription)")

    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )
  }
}