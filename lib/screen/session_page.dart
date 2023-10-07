import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ImageCardPage extends StatefulWidget {
  @override
  _ImageCardPageState createState() => _ImageCardPageState();
}

class _ImageCardPageState extends State<ImageCardPage> {
  final DatabaseReference database = FirebaseDatabase.instance.reference();
  String imageUrl = '';
  String text = '';

  @override
  void initState() {
    super.initState();

    // Listen for changes in the database
    database.child('latestImageUrl').onValue.listen((event) {
      setState(() {
        imageUrl = event.snapshot.value as String;
      });
    });

    database.child('latestPrompt').onValue.listen((event) {
      setState(() {
        text = event.snapshot.value as String;
      });
    });
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
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to StartPage
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Card(
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(10.0),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    height: 200.0,
                                    width: double.infinity,
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Center(
                                        child: CircularProgressIndicator(
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
                              : Center(
                                  child: CircularProgressIndicator(),
                                ), // Show a loader while waiting for imageUrl
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              text,
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
