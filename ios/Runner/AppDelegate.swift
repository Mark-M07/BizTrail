import Flutter
import UIKit
import GoogleMaps
import FirebaseCore
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    var channel: FlutterMethodChannel!

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()

        // Initialize Google Maps
        GMSServices.provideAPIKey("AIzaSyCkI7_eaRpS3YcXXt29lsFCdRy4zUZ59yk")

        // Set up MethodChannel for checking location accuracy
        let controller = window?.rootViewController as! FlutterViewController
        channel = FlutterMethodChannel(name: "com.biztrail.app/location_accuracy",
                                       binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "checkLocationAccuracy":
                self.checkLocationAccuracy(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Initialize location manager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        // Request when in use authorization at launch (optional, 
        // you can also request this in Dart using permission_handler plugin)
        locationManager.requestWhenInUseAuthorization()

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    @available(iOS 14.0, *)
    private func checkLocationAccuracy(result: @escaping FlutterResult) {
        let accuracyAuthorization = locationManager.accuracyAuthorization
        switch accuracyAuthorization {
        case .fullAccuracy:
            result("fullAccuracy")
        case .reducedAccuracy:
            result("reducedAccuracy")
        @unknown default:
            result("unknown")
        }
    }

    // CLLocationManagerDelegate methods (if needed)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle changes in location authorization if necessary
    }
}
