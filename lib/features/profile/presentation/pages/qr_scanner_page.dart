import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:developer' as developer;

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  static PageRoute<String?> route() {
    return MaterialPageRoute<String?>(builder: (_) => const QrScannerPage());
  }

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

// Bỏ 'with SingleTickerProviderStateMixin' vì không còn dùng AnimationController
class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _isTorchOn = false;

  // Không cần AnimationController nữa
  // AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    // Không cần khởi tạo animation
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndScan() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        final BarcodeCapture? result = await controller.analyzeImage(image.path);

        if (result != null && result.barcodes.isNotEmpty) {
          final String? code = result.barcodes.first.rawValue;
          if (code != null && mounted) {
            Navigator.of(context).pop(code);
            return;
          }
        }

        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy mã QR hợp lệ trong ảnh.')),
          );
        }

      }
    } catch (e) {
      developer.log("Lỗi quét ảnh: $e", name: "QrScannerPage");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã có lỗi xảy ra khi phân tích ảnh.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              setState(() => _isProcessing = true);

              final String? code = capture.barcodes.first.rawValue;
              if (code != null && code.isNotEmpty) {
                Navigator.of(context).pop(code);
              } else {
                setState(() => _isProcessing = false);
              }
            },
          ),

          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: QRScannerOverlayPainter(
              scanAreaSize: MediaQuery.of(context).size.width * 0.7,
            ),
          ),

          // Hiệu ứng tia laser quét đã được xóa bỏ
          // _buildLaserEffect(context),

          _buildHeaderAndControls(context),
        ],
      ),
    );
  }

  // Hàm này không còn cần thiết nữa, có thể xóa đi
  // Widget _buildLaserEffect(BuildContext context) { ... }

  Widget _buildHeaderAndControls(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text(
                  'Quét mã QR giới thiệu',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(
                  tooltip: 'Đèn flash',
                  onPressed: () {
                    controller.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  },
                  child: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off_outlined,
                    color: _isTorchOn ? Colors.amber : Colors.white,
                    size: 32,
                  ),
                ),
                _buildCircleButton(
                  tooltip: 'Tải ảnh QR',
                  onPressed: _pickImageAndScan,
                  child: const Icon(Icons.image_outlined, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required VoidCallback onPressed, required Widget child, required String tooltip}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.black.withOpacity(0.5),
          child: IconButton(
            onPressed: onPressed,
            icon: child,
            iconSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(tooltip, style: const TextStyle(color: Colors.white, fontSize: 12))
      ],
    );
  }
}

class QRScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;

  QRScannerOverlayPainter({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12))),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    final path = Path()
      ..moveTo(scanRect.left, scanRect.top + cornerLength)..lineTo(scanRect.left, scanRect.top)..lineTo(scanRect.left + cornerLength, scanRect.top)
      ..moveTo(scanRect.right - cornerLength, scanRect.top)..lineTo(scanRect.right, scanRect.top)..lineTo(scanRect.right, scanRect.top + cornerLength)
      ..moveTo(scanRect.right, scanRect.bottom - cornerLength)..lineTo(scanRect.right, scanRect.bottom)..lineTo(scanRect.right - cornerLength, scanRect.bottom)
      ..moveTo(scanRect.left + cornerLength, scanRect.bottom)..lineTo(scanRect.left, scanRect.bottom)..lineTo(scanRect.left, scanRect.bottom - cornerLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}