import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// <<< SỬA LẠI: Class này giờ sẽ trả về một String? >>>
class PaymentWebViewPage extends StatefulWidget {
  final String initialUrl;

  const PaymentWebViewPage({super.key, required this.initialUrl});

  static PageRoute<String?> route(String initialUrl) {
    return MaterialPageRoute<String?>( // <<< SỬA LẠI: Kiểu trả về là String?
      builder: (_) => PaymentWebViewPage(initialUrl: initialUrl),
      fullscreenDialog: true,
    );
  }

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  double _progress = 0;
  final successUrlPattern = 'https://piv-fertilizer-app.web.app/payment-return';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán an toàn'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(), // Trả về null khi người dùng tự đóng
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
            onLoadStop: (controller, url) {
              // Lắng nghe khi VNPAY điều hướng về URL thành công
              if (url != null && url.toString().startsWith(successUrlPattern)) {
                final responseCode = url.queryParameters['vnp_ResponseCode'];
                // Trả response code (ví dụ '00') về trang trước đó
                Navigator.of(context).pop(responseCode);
              }
            },
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(value: _progress),
        ],
      ),
    );
  }
}