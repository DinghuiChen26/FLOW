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


class ImageURLProvider with ChangeNotifier {
  String _imageURL = '';

  String get imageURL => _imageURL;

  void updateURL(String newURL) {
    _imageURL = newURL;
    print("updated");
    notifyListeners();
  }
}


class PromptProvider with ChangeNotifier {
  String _prompt = '';

  String get prompt => _prompt;

  void updatePrompt(String new_prompt) {
    _prompt = new_prompt;
    print("updated");
    notifyListeners();
  }
}
