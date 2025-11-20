import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ViewOnlinePage extends StatelessWidget {
  final String fileUrl;

  const ViewOnlinePage({super.key, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    final viewerUrl =
        'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(fileUrl)}';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(viewerUrl));

    return Scaffold(
      appBar: AppBar(
        title: const Text("View Online"),
        backgroundColor: Colors.orange,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
