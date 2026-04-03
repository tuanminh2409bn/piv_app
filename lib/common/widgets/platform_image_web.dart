// lib/common/widgets/platform_image_web.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Widget buildPlatformImage(XFile file, double? width, double? height, BoxFit fit) {
  return Image.network(
    file.path,
    width: width,
    height: height,
    fit: fit,
  );
}
