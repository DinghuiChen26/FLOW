//import 'dart:ffi';

// ignore_for_file: library_private_types_in_public_api, prefer_final_fields, prefer_typing_uninitialized_variables, deprecated_member_use, avoid_print, non_constant_identifier_names, body_might_complete_normally_nullable, no_leading_underscores_for_local_identifiers, unused_local_variable, use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:flow_app/providers/firebase.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
// import 'package:intl/intl.dart'; // Import the intl package
import 'package:path_provider/path_provider.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/texttospeech/v1.dart' as tts;
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'webview_page.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuidancePage extends StatefulWidget {
  const GuidancePage({super.key});

  @override
  _GuidancePageState createState() => _GuidancePageState();
}

class _GuidancePageState extends State<GuidancePage> {
  final TextEditingController _controller = TextEditingController();
  String _selectedVoice = "";
  int _time = 5;
  late final jplayer; // Create a player
  List<String> hintTags = [
    "calm",
    "mindfulness",
    "deep breath",
  ];
  FirebaseStorage storage = FirebaseStorage.instance;
  late OpenAI openAI;
  bool _isLoading = false; // Add this line to track the loading state
   bool _isTextFieldEnabled = true;
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  //ChatCTResponse? mResponse;
  @override
  void initState() {
    openAI = OpenAI.instance.build(
      token: '',
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 30)),
      enableLog: true,
    );
    jplayer = AudioPlayer();
    super.initState();
  }

  Future<void> _addSession(BuildContext context) async {
    final audioUrlProvider =
        Provider.of<AudioURLProvider>(context, listen: false);
    final imageUrlProvider =
        Provider.of<ImageURLProvider>(context, listen: false);
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    final String audioUrl = audioUrlProvider.audioURL;
    final String imageUrl = imageUrlProvider.imageURL;
    final String prompt = promptProvider.prompt;

    final DateTime now = DateTime.now();
    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');

    final String timestamp = '$year$month$day$hour$minute';

    final CollectionReference sessions =
        FirebaseFirestore.instance.collection('sessions');

    return sessions
        .doc(timestamp)
        .set({
          'audio url': audioUrl,
          'image url': imageUrl,
          'prompt': prompt,
        })
        .then((value) => print("Session Added"))
        .catchError((error) => print("Failed to add session: $error"));
  }

  Future<void> PromptToDatabase(String prompt) async {
    // Define a reference to the location where you want to save the image URL
    DatabaseReference pRef = database.reference().child('latestPrompt');

    // Set the value
    await pRef.set(prompt);
    print("Prompt saved to database");
  }

  Future<String?> _chatGpt3Example(String myPrompt, int time) async {
    int token_limit = 0;
    if (time == 1) {
      token_limit = 800;
    } else {
      token_limit = 2000;
    }
    final request = ChatCompleteText(messages: [
      Messages(role: Role.user, content: myPrompt),
    ], model: GptTurboChatModel(), maxToken: token_limit);

    try {
      final response = await openAI.onChatCompletion(request: request);
      if (response != null && response.choices.isNotEmpty) {
        return response.choices.first.message?.content;
      }
    } catch (e) {
      print("Error in _chatGpt3Example: $e");
      return "Error occurred";
    }
  }

  String prompt_prep(String userInput, int time) {
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    promptProvider.updatePrompt(userInput);
    PromptToDatabase(userInput);
    // Pre-formatted prompt template
    String template =
        """Please provide a guided meditation script in SSML format that lasts for $time minutes. The meditation should emphasize the following themes: $userInput. Ensure the script includes appropriate pauses and repetitions to extend the duration. Remember to use SSML tags like <speak>, <break>, and <emphasis> to structure the content.""";

    // Replace the placeholders with the user's input and time
    String completedPrompt = template
        .replaceAll('[USER_INPUT]', userInput)
        .replaceAll('[TIME]', time.toString());

    return completedPrompt;
  }

  Future<String> textToSpeech(String selectedVoice, String prompt) async {
    String voice_sel = '';

    if (selectedVoice == 'Voice 1') {
      voice_sel = 'C';
    } else {
      voice_sel = 'F';
    }
    // Define the API endpoint

    // Service account credentials
    final _credentials = ServiceAccountCredentials.fromJson(
      {
        "type": "service_account",
        "project_id": "flow-399713",
        "private_key_id": "",
        "private_key":
            "",
        "client_email": "cheng-828@flow-399713.iam.gserviceaccount.com",
        "client_id": "109644553059201697198",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/cheng-828%40flow-399713.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      },
    );

    // Define the auth client
    final _client = http.Client();
    final _authClient = await clientViaServiceAccount(
      _credentials,
      [tts.TexttospeechApi.cloudPlatformScope],
      baseClient: _client,
    );

    // Create the Text-to-Speech API client
    final ttsApi = tts.TexttospeechApi(_authClient);

    // Define the synthesis input
    final input = tts.SynthesisInput(ssml: prompt);

    // Define the voice selection
    final voice = tts.VoiceSelectionParams(
      languageCode: 'en-US',
      name: 'en-US-Neural2-$voice_sel', 
      ssmlGender: 'FEMALE',
    );

    // Define the audio configuration
    final audioConfig = tts.AudioConfig(audioEncoding: 'MP3');

    // Create the synthesis request
    final request = tts.SynthesizeSpeechRequest(
      input: input,
      voice: voice,
      audioConfig: audioConfig,
    );

    // Call the Text-to-Speech API
    final response = await ttsApi.text.synthesize(request);

    // Decode the base64 encoded audio data
    final audioData = base64Decode(response.audioContent!);

    // Save the audio data to a file
    final directory = await getTemporaryDirectory();
    final audioFile = File('${directory.path}/synthesized-audio.mp3');
    await audioFile.writeAsBytes(audioData);

    // Upload to Firebase Storage
    //FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage
        .ref()
        .child('synthesized-audio/${DateTime.now().toIso8601String()}.mp3');
    UploadTask uploadTask = ref.putFile(audioFile);
    TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
    String downloadUrl = await snapshot.ref.getDownloadURL();

    print("Audio file URL: $downloadUrl");

    return downloadUrl;

    // Close the auth client
  }

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
                        _controller.text += "$tag, "; // update the text box with the clicked tag
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
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Enter prompt for the voice guidance',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VoiceOption(
                      label: "Voice 1",
                      isSelected: _selectedVoice == "Voice 1",
                      onTap: () async {
                        setState(() {
                          _selectedVoice = "Voice 1";
                        });
                        // Play the audio
                        final duration = await jplayer.setUrl(// Load a URL
                            'https://firebasestorage.googleapis.com/v0/b/flow-43f6c.appspot.com/o/synthesized-audio%2F2023-09-25T13:23:21.572278.mp3?alt=media&token=30fd3a32-67d0-4522-a13a-6f4112b32950');
                        jplayer.play(); // Start playing
                        // await audioPlayer.play(UrlSource(
                        //     'https://firebasestorage.googleapis.com/v0/b/flow-43f6c.appspot.com/o/synthesized-audio%2F2023-09-25T13:23:21.572278.mp3?alt=media&token=30fd3a32-67d0-4522-a13a-6f4112b32950'));
                      },
                    ),
                    const SizedBox(width: 20.0),
                    VoiceOption(
                      label: "Voice 2",
                      isSelected: _selectedVoice == "Voice 2",
                      onTap: () async {
                        setState(() {
                          _selectedVoice = "Voice 2";
                        });
                        final duration = await jplayer.setUrl(// Load a URL
                            'https://firebasestorage.googleapis.com/v0/b/flow-43f6c.appspot.com/o/synthesized-audio%2F2023-09-25T13:27:22.317649.mp3?alt=media&token=494b71d9-c07a-4dd3-98d6-a7da12f02c6e');
                        jplayer.play();
                        // await audioPlayer.play(UrlSource(
                        //     'https://firebasestorage.googleapis.com/v0/b/flow-43f6c.appspot.com/o/synthesized-audio%2F2023-09-25T13:27:22.317649.mp3?alt=media&token=494b71d9-c07a-4dd3-98d6-a7da12f02c6e'));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Slider(
                  value: _time.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_time minutes',
                  onChanged: (double value) {
                    setState(() {
                      _time = value.round();
                    });
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                            bool _isTextFieldEnabled = true;
                          });
                          //print(_isLoading);
                          String fprompt = prompt_prep(_controller.text, _time);
                          //print(fprompt);
                          final gptResponse =
                              await _chatGpt3Example(fprompt, _time);
                          print("GPT-3.5 Turbo Response: $gptResponse");
                          String url =
                              await textToSpeech(_selectedVoice, gptResponse!);
                          final audioURLProvider =
                              Provider.of<AudioURLProvider>(context,
                                  listen: false);
                          audioURLProvider.updateURL(url);
                          _addSession(context);
                          // context.read<AudioURLProvider>().updateURL(url);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => WebViewPage(),
                            settings: const RouteSettings(name: "/webViewPage"),
                          ));

                          setState(() {
                            _isLoading =
                                false; // Set loading to false when actions are done
                          });
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
                  child: const Text('Generate'),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
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

class VoiceOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const VoiceOption({super.key, 
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
