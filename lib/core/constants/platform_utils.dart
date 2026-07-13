import 'package:flutter/foundation.dart';

class PlatformUtils {
  static String get devicePlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ANDROID';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'IOS';
    }
    return 'UNKNOWN'; // สำหรับกรณีอื่นๆ เช่น Web หรือ Desktop
  }
}
