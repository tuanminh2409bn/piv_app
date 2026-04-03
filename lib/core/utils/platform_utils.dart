// lib/core/utils/platform_utils.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_io.dart'
    if (dart.library.html) 'platform_utils_web.dart';

class PlatformUtils {
  static bool get isWeb => kIsWeb;

  static bool get isAndroid => getIsAndroid();
  static bool get isIOS => getIsIOS();
  static bool get isMobile => isAndroid || isIOS;
  static String get operatingSystem => getOperatingSystem();
}
