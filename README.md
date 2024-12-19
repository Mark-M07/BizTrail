# BizTrail

BizTrail is a mobile application designed to promote local businesses and provide incentives for people to visit them. Users can discover local businesses, earn points by visiting locations and scanning QR codes, and earn raffle tickets for prizes.

## Features

- User Authentication (Email, Google, and Apple Sign In for iOS)
- Interactive Map of Business Locations
- QR Code Scanning
- Geolocation Verification
- Points System
- Raffle Ticket Rewards
- Activity Tracking
- Business Discovery

## Prerequisites

Before you begin, ensure you have installed:
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / XCode (depending on target platform)
- Firebase CLI

## Getting Started

1. Clone the repository:
```bash
git clone [repository-url]
cd biztrail
```

2. Set up Firebase:
   - Copy `lib/firebase_options.template.dart` to `lib/firebase_options.dart`
   - Replace placeholder values with your Firebase configuration
   - Place required Firebase configuration files:
     - Android: `google-services.json` in `android/app/`
     - iOS/macOS: `GoogleService-Info.plist` in `ios/Runner/` and `macos/Runner/`

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Platform-Specific Setup

### Android
- Ensure Google Maps API key is configured in `android/app/src/main/AndroidManifest.xml`
- Configure Firebase as per Android requirements

### iOS
- Set up Apple Sign In capability in Xcode
- Configure location and camera permissions
- Set up Firebase for iOS
- Configure Google Maps for iOS

## Development Notes

- Map styles are defined in `lib/constants/map_styles.dart`
- Authentication services are in `lib/services/auth_service.dart`
- Firebase configuration template is provided in `firebase_options.template.dart`

## Building for Release

### Android
```bash
flutter build appbundle
```

### iOS
```bash
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
flutter pub get
cd ios
pod install
cd ..
```
```bash
flutter build ios
```
Then archive and distribute through Xcode.

## Contributing
```bash
git add .
git commit -m "Commit message"
git push origin main
```

## Contact

Mark Minehan/Social Sites - [\[contact information\]](https://www.socialsites.com.au/)

Project Link: [\[repository-url\]](https://github.com/Mark-M07/BizTrail/)
