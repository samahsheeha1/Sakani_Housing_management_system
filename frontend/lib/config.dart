import 'dart:io';
import 'package:flutter/foundation.dart';

String getBaseUrl() {
  if (kIsWeb) {
    return "http://127.0.0.1:5000"; // Web browser
  } else if (Platform.isAndroid) {
    return isRunningOnEmulator()
        ? "http://10.0.2.2:5000" // Android Emulator
        : "http://192.168.137.1:5000"; // Replace with your local IP for physical devices
  } else if (Platform.isIOS) {
    return "http://127.0.0.1:5000"; // iOS Simulator
  } else {
    return "http://192.168.137.1:5000"; // Replace with your local IP for other devices
  }
}

/// Check if the app is running on an emulator
bool isRunningOnEmulator() {
  const emulatorIdentifiers = [
    "google_sdk",
    "Emulator",
    "Android SDK built for x86"
  ];
  return emulatorIdentifiers.any((identifier) =>
      Platform.environment.containsKey("DEVICE_IDENTIFIER") &&
      Platform.environment["DEVICE_IDENTIFIER"] == identifier);
}
