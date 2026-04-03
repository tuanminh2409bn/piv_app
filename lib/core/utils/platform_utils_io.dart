// lib/core/utils/platform_utils_io.dart
import 'dart:io' as io;

bool getIsAndroid() => io.Platform.isAndroid;
bool getIsIOS() => io.Platform.isIOS;
String getOperatingSystem() => io.Platform.operatingSystem;
