# Call Invitation

----

## 1. Clone the Repository
```bash
    git clone https://github.com/huzaifashah00/call_invitation.git
```

## 2. Install Dependencies
```bash
    flutter pub get
```

## 3. Configure ZegoCloud
- Get AppID & AppSign from ZegoCloud Dashboard.
- Update them in lib\zego_sdk_key_center.dart:
```bash
    const int appID = YOUR_APP_ID;
    const String appSign = "YOUR_APP_SIGN";
```

## 4. Run the App
```bash
    flutter run
```

## 🔧 Troubleshooting
- Missing Permissions?
-- Update AndroidManifest.xml (Android) & Info.plist (iOS) for camera/mic.
- ZegoCloud Errors?
-- Ensure correct AppID & AppSign.
-- Check Zego Docs.


## Project Structure
```bash
lib
├── components
├── internal
├── utils
├── zego_sdk_manager.dart
├── live_audio_room_manager.dart
├── zego_live_streaming_manager.dart
├── zego_call_manager.dart
├── zego_sdk_key_center.dart
├── main.dart
└── pages
    ├── login_page.dart
    ├── home_page.dart
    ├── audio_room
    ├── call
    └── live_streaming
```

## 📱 Features
### ✅ Audio & Video Calling (1-on-1 or Group)
### ✅ Call Invitation System (Incoming/Outgoing calls)
### ✅ Permissions Handling (permission_handler)
### ✅ User Authentication & Session Management (shared_preferences)
### ✅ Image Caching (cached_network_image, flutter_cache_manager)
### ✅ Secure Data Handling (encrypt)
### ✅ Animated SVGs (svgaplayer_flutter)
### ✅ Floating Call Window (floating)
### ✅ Notifications (x_overlay)