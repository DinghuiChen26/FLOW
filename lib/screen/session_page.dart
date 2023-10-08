// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:firebase_database/firebase_database.dart';
import 'package:flow_app/screen/home_page.dart';
// import 'package:flow_app/screen/voice_guidance.dart';
import 'package:flow_app/screen/webview_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
// import 'package:webview_flutter/webview_flutter.dart';

import '../providers/firebase.dart';

class SessionsGridPage extends StatefulWidget {
  const SessionsGridPage({super.key});

  @override
  _SessionsGridPageState createState() => _SessionsGridPageState();
}

class _SessionsGridPageState extends State<SessionsGridPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseDatabase database = FirebaseDatabase.instance;

  String decodeTimestamp(String timestamp) {
    final String month = timestamp.substring(4, 6);
    final String day = timestamp.substring(6, 8);
    final String hour = timestamp.substring(8, 10);
    final String minute = timestamp.substring(10, 12);
    return '$month/$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF83a4d4), Color(0xFFb6fbff)],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('sessions').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No sessions found.'));
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // number of columns
                          childAspectRatio: 0.8,
                          crossAxisSpacing:
                              10, // Horizontal spacing between cards
                          mainAxisSpacing: 10, // Vertical spacing between cards
                        ),
                        itemCount: snapshot.data!.docs.length +
                            1, // Increment itemCount by 1
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const MyHomePage()),
                                );
                              },
                              child: Card(
                                elevation: 5.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    size: 48,
                                  ),
                                ),
                              ),
                            );
                          }
                          final doc = snapshot.data!.docs[index - 1];
                          final Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () async {
                              // Define a reference to the location where you want to save the image URL
                              DatabaseReference imgRef =
                                  database.reference().child('latestImageUrl');
                              await imgRef.set(data['image url']);
                              final audioURLProvider =
                                  // ignore: use_build_context_synchronously
                                  Provider.of<AudioURLProvider>(context,
                                      listen: false);

                              audioURLProvider.updateURL(data['audio url']);
                              // ignore: use_build_context_synchronously
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebViewPage(),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 5.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Stack(
                                children: <Widget>[
                                  data['image url'] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          child: Image.network(
                                            data['image url'],
                                            fit: BoxFit.cover,
                                            height: double.infinity,
                                            width: double.infinity,
                                            loadingBuilder:
                                                (BuildContext context,
                                                    Widget child,
                                                    ImageChunkEvent?
                                                        loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          (loadingProgress
                                                                  .expectedTotalBytes ??
                                                              1)
                                                      : null,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            10.0), // Set border radius to circular 10
                                        color: Colors.black.withOpacity(
                                            0.5), // Optional: Set color of the container
                                      ),
                                      // Semi-transparent background
                                      child: Center(
                                        child: Text(
                                          decodeTimestamp(doc
                                              .id), // Decode the document's ID to display the timestamp
                                          style: const TextStyle(
                                              fontSize: 16.0,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
