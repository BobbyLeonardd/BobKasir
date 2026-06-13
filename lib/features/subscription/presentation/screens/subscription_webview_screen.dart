import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/subscription_provider.dart';

/// Hosts the Midtrans Snap payment page inside a WebView. Snap's JS callbacks
/// redirect to a `bobkasir://payment/<result>` URL which we intercept to pop the
/// screen with the outcome string (success/pending/error/close).
class SubscriptionWebViewScreen extends StatefulWidget {
  final CheckoutResult checkout;
  const SubscriptionWebViewScreen({super.key, required this.checkout});

  @override
  State<SubscriptionWebViewScreen> createState() =>
      _SubscriptionWebViewScreenState();
}

class _SubscriptionWebViewScreenState
    extends State<SubscriptionWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _popped = false;

  static const _callbackScheme = 'bobkasir://payment/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(_callbackScheme)) {
              final result = request.url.substring(_callbackScheme.length);
              _finish(result);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildSnapHtml(), baseUrl: _snapOrigin());
  }

  String _snapOrigin() {
    // Origin matters for Snap's hosted assets; derive it from the snap.js URL.
    final uri = Uri.tryParse(widget.checkout.snapUrl);
    if (uri != null && uri.hasAuthority) {
      return '${uri.scheme}://${uri.host}';
    }
    return 'https://app.sandbox.midtrans.com';
  }

  String _buildSnapHtml() {
    final token = widget.checkout.snapToken;
    final snapUrl = widget.checkout.snapUrl;
    final clientKey = widget.checkout.clientKey;
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="$snapUrl" data-client-key="$clientKey"></script>
</head>
<body onload="startPay()">
  <script>
    function done(result){ window.location.href = '$_callbackScheme' + result; }
    function startPay(){
      if (typeof snap === 'undefined') { done('error'); return; }
      snap.pay('$token', {
        onSuccess: function(){ done('success'); },
        onPending: function(){ done('pending'); },
        onError:   function(){ done('error'); },
        onClose:   function(){ done('close'); }
      });
    }
  </script>
</body>
</html>
''';
  }

  void _finish(String result) {
    if (_popped) return;
    _popped = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_popped) _popped = true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => _finish('close'),
          ),
          title: const Text('Pembayaran'),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brushedGold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
