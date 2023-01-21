import 'dart:async';
import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/ui/widgets/SimpleAppBar.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewWidget extends StatefulWidget {
  const WebViewWidget({Key? key, required this.route, required this.idx})
      : super(key: key);
  final String route;
  final int idx;

  @override
  _WebViewWidgetState createState() => _WebViewWidgetState();
}

class _WebViewWidgetState extends State<WebViewWidget> {
  double _progress = 0;
  String route = '';

  @override
  void initState() {
    super.initState();
    route = widget.route;
  }

  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: WebView(
            initialUrl: successUrl + route,
            javascriptMode: JavascriptMode.unrestricted,
            onPageFinished: (finish) {
              setState(() {
                _progress = 1;
              });
            },
            onProgress: (int progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
          ),
        ),
        _progress < 1
            ? SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                    value: _progress,
                    color: Colors.red,
                    backgroundColor: Colors.grey),
              )
            : Container(),
      ],
    );
  }
}
