// lib/common/widgets/platform_image_io.dart
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Widget buildPlatformImage(XFile file, double? width, double? height, BoxFit fit) {
  return Image.file(
    io.File(file.path),
    width: width,
    height: height,
    fit: fit,
  );
}
