import 'dart:convert';
import 'dart:io';

import 'package:flow_app/screen/home_page.dart';
import 'package:flow_app/screen/webview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
//import 'html_generator.dart';
//import 'webview_page.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screen/voice_guidance.dart';
import 'screen/login.dart';
import 'providers/firebase.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that you've bound to the Flutter engine
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ChangeNotifierProvider(
    create: (context) => AudioURLProvider(),
      child: MyApp(),
  ),);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //title: 'Stereoscopic Image Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: StartPage(),
    );
  }
}


