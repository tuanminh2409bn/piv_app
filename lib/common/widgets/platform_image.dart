// lib/common/widgets/platform_image.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'platform_image_stub.dart'
    if (dart.library.io) 'platform_image_io.dart'
    if (dart.library.html) 'platform_image_web.dart';

class PlatformXImage extends StatelessWidget {
  final XFile file;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PlatformXImage({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return buildPlatformImage(file, width, height, fit);
  }
}
