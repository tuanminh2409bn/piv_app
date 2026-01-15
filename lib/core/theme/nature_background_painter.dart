import 'package:flutter/material.dart';

class NatureBackgroundPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color accent;

  NatureBackgroundPainter({
    required this.color1,
    required this.color2,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Góc trên trái: Lá cây lớn mềm mại
    paint.color = color1;
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(0, size.height * 0.35);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.3, size.width * 0.4, size.height * 0.15);
    path1.quadraticBezierTo(size.width * 0.6, 0, size.width * 0.7, 0);
    path1.close();
    canvas.drawPath(path1, paint);

    // 2. Góc dưới phải: Đồi nhỏ / Đất
    paint.color = color2;
    final path2 = Path();
    path2.moveTo(size.width, size.height);
    path2.lineTo(size.width, size.height * 0.75);
    path2.quadraticBezierTo(size.width * 0.7, size.height * 0.8, size.width * 0.5, size.height * 0.9);
    path2.quadraticBezierTo(size.width * 0.2, size.height, 0, size.height);
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
    
    // 3. Điểm nhấn: Các đốm tròn (Hạt giống/Phấn hoa)
    paint.color = accent;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.25), 8, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.85), 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}