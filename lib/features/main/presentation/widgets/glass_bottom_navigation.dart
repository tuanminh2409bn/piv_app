import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;
  final List<GlassNavigationItem> items;

  const GlassBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAndroid = Platform.isAndroid;
    // Độ dày thanh kính: Cực kỳ mỏng và mảnh mai
    final double barHeight = isAndroid ? 52.0 : 62.0; 
    
    // Lấy padding an toàn từ hệ thống (chiều cao thanh điều hướng)
    final double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    // Độ cao khung: Điều chỉnh khoảng cách lơ lửng so với đáy màn hình
    // Tăng nhẹ 2 đơn vị cho iOS so với bản trước để cân đối hơn
    final double bottomPadding = isAndroid 
        ? (10.0 + safeAreaBottom) 
        : (safeAreaBottom > 0 ? safeAreaBottom - 8.0 : 10.0);

    final double iconSize = isAndroid ? 23.0 : 25.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      child: SizedBox(
        height: barHeight + 6, 
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // --- LỚP KÍNH MỜ (MỎNG NHẤT) ---
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(
                begin: 0,
                end: currentIndex.toDouble(),
              ),
              builder: (context, animatedIndex, child) {
                return ClipPath(
                  clipper: _DeepCurvedClipper(
                    index: animatedIndex,
                    totalItems: items.length,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: (Theme.of(context).cardTheme.color ?? Colors.white)
                            .withOpacity(0.55),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.0),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // --- NỘI DUNG ICON & TEXT (ĐÃ TỐI ƯU KHÔNG GIAN) ---
            SizedBox(
              height: barHeight + 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onItemTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        // Nhô lên cực nhẹ (-4px) cho thanh bar mỏng
                        transform: Matrix4.identity()
                          ..translate(0.0, isSelected ? -4.0 : 0.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSelected ? 6 : 0), 
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.25),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    )
                                  : null,
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: iconSize,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected 
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade600,
                                fontSize: 8.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2), // Padding đáy tối thiểu
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  GlassNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _DeepCurvedClipper extends CustomClipper<Path> {
  final double index;
  final int totalItems;

  _DeepCurvedClipper({required this.index, required this.totalItems});

  @override
  Path getClip(Size size) {
    final path = Path();
    final double width = size.width;
    final double height = size.height;
    final double itemWidth = width / totalItems;
    final double centerX = (index * itemWidth) + (itemWidth / 2);
    
    const double notchRadius = 34.0; 
    const double notchDepth = 10.0; // Notch nông hơn để cân đối với bar mỏng
    const double cornerRadius = 25.0;

    final double notchStart = centerX - notchRadius;
    final double notchEnd = centerX + notchRadius;

    path.moveTo(0, cornerRadius);
    if (notchStart >= cornerRadius) {
      path.quadraticBezierTo(0, 0, cornerRadius, 0);
      path.lineTo(notchStart, 0);
    } else if (notchStart > 0) {
      path.quadraticBezierTo(0, 0, notchStart, 0);
    } else {
      path.lineTo(0, 0);
    }

    path.cubicTo(
      centerX - (notchRadius * 0.6), 0,
      centerX - (notchRadius * 0.45), notchDepth,
      centerX, notchDepth,
    );

    path.cubicTo(
      centerX + (notchRadius * 0.45), notchDepth,
      centerX + (notchRadius * 0.6), 0,
      notchEnd, 0,
    );

    final double rightTrigger = width - cornerRadius;
    if (notchEnd <= rightTrigger) {
      path.lineTo(rightTrigger, 0);
      path.quadraticBezierTo(width, 0, width, cornerRadius);
    } else if (notchEnd < width) {
      path.quadraticBezierTo(width, 0, width, cornerRadius);
    } else {
      path.lineTo(width, 0);
      path.lineTo(width, cornerRadius);
    }

    path.lineTo(width, height - cornerRadius);
    path.quadraticBezierTo(width, height, width - cornerRadius, height);
    path.lineTo(cornerRadius, height);
    path.quadraticBezierTo(0, height, 0, height - cornerRadius);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _DeepCurvedClipper oldClipper) {
    return oldClipper.index != index;
  }
}