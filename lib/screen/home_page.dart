// ignore_for_file: unused_import, library_private_types_in_public_api, prefer_interpolation_to_compose_strings, prefer_typing_uninitialized_variables, non_constant_identifier_names, deprecated_member_use, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
//import 'html_generator.dart';
//import 'webview_page.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'voice_guidance.dart';
import 'login.dart';
import '../providers/firebase.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final storage = FirebaseStorage.instance;
  final TextEditingController _controller = TextEditingController();
  // String? _htmlString;
  late String prompt;
  late var img_path;
  bool _isLoading = false;
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  List<String> hintTags = [
    "sunset",
    "lake",
    "forest",
    "lavender",
  ];
  bool _isTextFieldEnabled = true;

  Future<String> fetchImageFromAPI(String prompt) async {


    const url =
        "https://6cac3gr7opzffdhsul272khe6y0bvhaf.lambda-url.eu-west-2.on.aws/";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"prompt": prompt}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("fetched image");
      return "https://copernicai.com/" + data['image'];
    } else {
      throw Exception('Failed to fetch image');
    }
  }

  Future<String> uploadImageToFirebase(String imagePath) async {
    // Get the current timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a reference to the loc ation you want to upload to in Firebase Storage
    final ref = storage.ref().child('images/$timestamp.jpg');

    // Upload the file to Firebase Storage
    final uploadTask = ref.putFile(File(imagePath));

    // Check for any errors during the upload
    await uploadTask.whenComplete(() => {});

    // Once the upload is complete, retrieve the download URL
    final downloadUrl = await ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> writeToDatabase(String imageUrl) async {
    // Define a reference to the location where you want to save the image URL
    DatabaseReference imgRef = database.reference().child('latestImageUrl');

    // Set the value
    await imgRef.set(imageUrl);
  }

  Future<String> downloadImage(String imageUrl) async {
    // Make a GET request to fetch the image data
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      // Get the system temp directory to save the downloaded image
      final directory = await getTemporaryDirectory();

      // Create a file in the temp directory
      // The file name is generated from the last segment of the image URL
      final file = File('${directory.path}/${imageUrl.split("/").last}');

      // Write the image data to the file
      await file.writeAsBytes(response.bodyBytes);

      final file_path = file.path;
      print(file_path);

      // Convert the webp image to jpg
      String jpgPath = await convertWebPToJPG(file.path);

      print(jpgPath);

      return jpgPath;
    } else {
      throw Exception('Failed to download image from $imageUrl');
    }
  }

  Future<String> convertWebPToJPG(String webpPath) async {
    // Read the webp image from the file
    List<int> bytes = await File(webpPath).readAsBytes();
    Uint8List uint8List = Uint8List.fromList(bytes);
    img.Image? image = img.decodeWebP(uint8List);

    if (image != null) {
      // Convert the image to jpg
      List<int> jpg = img.encodeJpg(image);

      // Save the jpg image to the file system
      final directory = await getTemporaryDirectory();
      final jpgFile = File('${directory.path}/converted_image.jpg');
      await jpgFile.writeAsBytes(jpg);

      return jpgFile.path;
    } else {
      throw Exception('Failed to decode webp image');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF83a4d4), Color(0xFFb6fbff)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Wrap(
                  spacing: 8.0, // space between tags
                  children: hintTags.map((tag) {
                    return InkWell(
                      onTap: () {
                        _controller.text +=
                            "$tag, "; // update the text box with the clicked tag
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.3), // translucent background
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
                TextField(
                  enabled: _isTextFieldEnabled,
                  //onChanged: (value) => prompt = value,
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Enter your prompt here',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16.0),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          prompt = _controller.text;
                          setState(() {
                            _isLoading = true;
                            _isTextFieldEnabled = false;
                          });
                          try {
                            final promptProvider = Provider.of<PromptProvider>(
                                context,
                                listen: false);

                            promptProvider.updatePrompt(prompt);
                            String result = await fetchImageFromAPI(prompt);
                            img_path = await downloadImage(result);

                            // Upload the image to Firebase Storage
                            String firebaseUrl =
                                await uploadImageToFirebase(img_path);
                            print("Image uploaded to Firebase: $firebaseUrl");

                            // Write the image URL to Firebase Realtime Database
                            await writeToDatabase(firebaseUrl);
                            final imageURLProvider =
                                Provider.of<ImageURLProvider>(context,
                                    listen: false);

                            imageURLProvider.updateURL(firebaseUrl);

                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  GuidancePage(), // Use the Firebase URL here
                            ));
                          } catch (e) {
                            print("Error: $e");
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    shadowColor: Colors.black.withOpacity(0.1),
                    elevation: 5.0,
                  ),
                  child: const Text('Next'),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
