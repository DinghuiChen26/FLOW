import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../providers/firebase.dart';

class WebViewPage extends StatefulWidget {
  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final jplayer; // Create a player

  @override
  void initState() async {
    super.initState();
    final audioURLProvider =
        Provider.of<AudioURLProvider>(context, listen: false);
    jplayer = AudioPlayer();
    final duration = await jplayer.setUrl(audioURLProvider.audioURL);
    jplayer.play();
    // Play the audio after a delay of 10 seconds
    // Future.delayed(Duration(seconds: 10), () async {
    //   await audioPlayer.play(UrlSource(audioURLProvider.audioURL));
    // });
  }

  @override
  void dispose() async {
    await jplayer.stop();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    await jplayer.stop();
    return true; // Allow the pop action to continue
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: WebView(
          initialUrl: 'https://flow-43f6c.web.app/',
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith('https://flow-43f6c.web.app/')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context); // Pop back to the previous screen
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
          backgroundColor: Colors.blue,
          mini: true, // Set to false if you want a regular sized FAB
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}

class WebViewPageObserver extends NavigatorObserver {
  final Function() onPagePopped;

  WebViewPageObserver({required this.onPagePopped});

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route.settings.name == "/webViewPage") {
      onPagePopped();
    }
    super.didPop(route, previousRoute);
  }
}
