// lib/common/widgets/responsive_wrapper.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool isForm;
  final Color? backgroundColor; // Cho phép tùy chỉnh màu nền
  final bool showShadow; // Cho phép ẩn/hiện đổ bóng

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.isForm = false,
    this.backgroundColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    double effectiveMaxWidth = maxWidth ?? (isForm ? 600 : 1000);

    return Container(
      // Nền của toàn bộ vùng trống trên trình duyệt
      color: backgroundColor ?? Colors.grey.shade100, 
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: Container(
            decoration: BoxDecoration(
              // Nền của khối nội dung
              color: backgroundColor ?? Colors.white, 
              boxShadow: showShadow ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
