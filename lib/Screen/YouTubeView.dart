import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class YouTubeView extends StatefulWidget {
  @override
  _YouTubeViewState createState() => _YouTubeViewState();
}

class _YouTubeViewState extends State<YouTubeView> {
  double _progress = 0;
  InAppWebViewController? webViewController;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('YouTube'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          InAppWebView(
            onZoomScaleChanged: (controller, oldScale, newScale) =>
                newScale = 2,
            initialUrlRequest: URLRequest(
              url: Uri.parse('https://www.youtube.com/NASA'),
            ),
            onWebViewCreated: ((controller) => webViewController = controller),
            onProgressChanged: ((controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            }),
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
      ),
    );
  }
}
