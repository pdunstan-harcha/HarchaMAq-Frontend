import 'dart:io';

class PlatformHelper {
  static bool get isWeb => false;
  static bool get isAndroid => Platform.isAndroid;
  static String get platformName => Platform.operatingSystem;
}
