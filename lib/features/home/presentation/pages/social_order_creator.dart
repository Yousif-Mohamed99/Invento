import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:invento/features/home/presentation/pages/create_order_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SmartOrderCreator extends StatefulWidget {
  const SmartOrderCreator({super.key});

  @override
  State<SmartOrderCreator> createState() => _SmartOrderCreatorState();
}

class _SmartOrderCreatorState extends State<SmartOrderCreator> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..loadRequest(Uri.parse("https://www.instagram.com/direct/inbox/"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("المساعد الذكي"),
        actions: [
          _buildPlatformIcon(
            FontAwesomeIcons.facebookMessenger,
            "https://www.messenger.com/",
          ),
          _buildPlatformIcon(
            FontAwesomeIcons.instagram,
            "https://www.instagram.com/direct/inbox/",
          ),
          _buildPlatformIcon(
            FontAwesomeIcons.tiktok,
            "https://www.tiktok.com/inbox",
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          _buildDraggableForm(),
        ],
      ),
    );
  }

  Widget _buildPlatformIcon(IconData icon, String url) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () => _controller.loadRequest(Uri.parse(url)),
    );
  }

  Widget _buildDraggableForm() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
              ),
            ],
          ),

          child: CreateOrderScreen(scrollController: scrollController),
        );
      },
    );
  }
}
