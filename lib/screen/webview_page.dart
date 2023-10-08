// ignore_for_file: library_private_types_in_public_api, unused_local_variable, avoid_print, use_build_context_synchronously, sort_child_properties_last

import 'package:flow_app/screen/login.dart';
import 'package:flow_app/screen/session_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../providers/firebase.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final AudioPlayer jplayer; // Create a player

  @override
  void initState() {
    super.initState();
    jplayer = AudioPlayer();

    // Create a delay, then execute your asynchronous code
    Future.delayed(const Duration(seconds: 10), () async {
      final audioURLProvider =
          Provider.of<AudioURLProvider>(context, listen: false);
      try {
        final duration = await jplayer.setUrl(audioURLProvider.audioURL);
        jplayer.play();
      } catch (e) {
        print('Failed to play audio: $e');
      }
    });
  }

  @override
  void dispose() {
    jplayer.dispose();
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
        body: GestureDetector(
          onHorizontalDragEnd: (details) {
            // Check if the swipe is a left swipe
            if (details.primaryVelocity! < 0) {
              // Navigate to StartPage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StartPage()),
              );
            }
          },
          child: WebView(
            initialUrl: 'https://flow-43f6c.web.app/',
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest request) {
              if (request.url.startsWith('https://flow-43f6c.web.app/')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await jplayer.stop();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SessionsGridPage()),
            );
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
          backgroundColor: Colors.blue,
          mini: true, // Set to false if you want a regular sized FAB
          shape: const RoundedRectangleBorder(
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
