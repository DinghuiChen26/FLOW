import 'dart:convert';
import 'dart:io';

import 'package:flow_app/screen/home_page.dart';
import 'package:flow_app/screen/webview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screen/voice_guidance.dart';
import 'screen/login.dart';
import 'providers/firebase.dart'; // Make sure this import path is correct
import 'package:provider/provider.dart';
import 'screen/image_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioURLProvider()),
        ChangeNotifierProvider(create: (context) => ImageURLProvider()),
        ChangeNotifierProvider(create: (context) => PromptProvider()),
        // ... other providers
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: StartPage(),
    );
  }
}
