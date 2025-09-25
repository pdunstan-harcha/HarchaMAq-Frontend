import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class ReciboWebViewScreen extends StatelessWidget {
  final String htmlRecibo;
  const ReciboWebViewScreen({super.key, required this.htmlRecibo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recibo de recarga')),
      body: WebViewWidget(
        controller: WebViewController()
          ..loadHtmlString(htmlRecibo)
          ..setJavaScriptMode(JavaScriptMode.unrestricted),
      ),
    );
  }
}
