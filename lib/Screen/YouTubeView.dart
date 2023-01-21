import 'dart:async';
import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/ui/widgets/SimpleAppBar.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
class YouTubeView extends StatefulWidget {
  @override
  _YouTubeViewState createState() => _YouTubeViewState();
}

class _YouTubeViewState extends State<YouTubeView> {
  double _progress = 0;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: getSimpleAppBar('YouTube', context),
      body: Stack(
        children: [
          WebView(
            initialUrl: youtubeBaseUrl + '@NASA',
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
