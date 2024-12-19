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

        // Initialize Google Maps using the Firebase-generated iOS API key
        let apiKey = "AIzaSyAAlmjoVHoyf3VKG8ZE0fF2zLzgWhJOqn4"
        GMSServices.provideAPIKey(apiKey)
        
        // Print debug info
        print("Google Maps SDK initialized with key: \(apiKey)")
        print("Google Maps SDK version: \(GMSServices.sdkVersion())")
        
        // Enable metal renderer
        GMSServices.setMetalRendererEnabled(true)
        
        // Add debug check for map rendering
        let testMapView = GMSMapView()
        print("Map view initialized")

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
        locationManager.requestWhenInUseAuthorization()
        
        print("Initial location authorization status: \(locationManager.authorizationStatus.rawValue)")

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

    // Enhanced CLLocationManagerDelegate method with debug info
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization changed to status: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse:
            print("Location authorized when in use")
        case .authorizedAlways:
            print("Location authorized always")
        case .denied:
            print("Location authorization denied")
        case .restricted:
            print("Location authorization restricted")
        case .notDetermined:
            print("Location authorization not determined")
        @unknown default:
            print("Unknown location authorization status")
        }
    }
}