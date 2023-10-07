import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AudioURLProvider with ChangeNotifier {
  String _audioURL = '';

  String get audioURL => _audioURL;

  void updateURL(String newURL) {
    _audioURL = newURL;
    print("updated");
    notifyListeners();
  }
}
