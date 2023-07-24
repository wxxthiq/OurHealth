import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../pages/call_page.dart';
import '../service/notification_service.dart';

class chatPage extends StatefulWidget {
  final String doctorEmail;
  final String patientEmail;
  final String currentUser;


  const chatPage({
    Key? key,
    required this.doctorEmail,
    required this.patientEmail,
    required this.currentUser,
  }) : super(key: key);

  @override
  _chatPageState createState() => _chatPageState();
}

class _chatPageState extends State<chatPage> {
  final TextEditingController _messageController = TextEditingController();
  VideoPlayerController? _videoPlayerController;
  Future<void>? _initializeVideoPlayerFuture;
  String get currentUser => widget.currentUser;

  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();

  }

  String getAppBarTitle(String currentUser, String doctorFullName, String patientFullName) {
    if (currentUser == 'doctor') {
      return patientFullName;
    } else {
      return doctorFullName;
    }
  }

  Future<String> getDoctorFullName(String doctorEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: doctorEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final document = snapshot.docs[0];
      return document['fullName'] as String;
    } else {
      // Handle the case where the document is not found or the snapshot is empty
      return ''; // Return an empty string or an appropriate value
    }
  }

  Future<String> getDoctorProfilePic(String doctorEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: doctorEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final document = snapshot.docs[0];
      return document['profilePic'] as String;
    } else {
      // Handle the case where the document is not found or the snapshot is empty
      return ''; // Return an empty string or an appropriate value
    }
  }

  Future<String> getPatientFullName(String patientEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: patientEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final document = snapshot.docs[0];
      return document['fullName'] as String;
    } else {
      // Handle the case where the document is not found or the snapshot is empty
      return ''; // Return an empty string or an appropriate value
    }
  }

  Future<String> getPatientProfilePic(String patientEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: patientEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final document = snapshot.docs[0];
      return document['profilePic'] as String;
    } else {
      // Handle the case where the document is not found or the snapshot is empty
      return ''; // Return an empty string or an appropriate value
    }
  }
  @override
  void dispose() {
    _messageController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _sendMessage() {
    String sender = widget.patientEmail;

    if (widget.currentUser == 'doctor') {
      sender = widget.doctorEmail;
    }

    final String message = _messageController.text.trim();

    if (message.isNotEmpty) {
      FirebaseFirestore.instance.collection('chats').add({
        'sender': sender,
        'message': message,
        'doctorEmail': widget.doctorEmail,
        'patientEmail': widget.patientEmail,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    _messageController.clear();
  }

  Future<void> _uploadFile(String fileType) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await (fileType == 'image'
        ? picker.pickImage(source: ImageSource.gallery)
        : picker.pickVideo(source: ImageSource.gallery));

    if (pickedFile != null) {
      if (fileType == 'image') {
        File selectedFile = File(pickedFile.path);
        _showConfirmationDialog(selectedFile, 'image');
      } else if (fileType == 'video') {
        File selectedFile = File(pickedFile.path);
        _showConfirmationDialog(selectedFile, 'video');
      }
    }
  }

  Future<void> _showConfirmationDialog(File selectedFile, String fileType) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Do you want to upload this file?'),
            SizedBox(height: 16),
            Center(
              child: fileType == 'image'
                  ? Image.file(selectedFile)
                  : _buildVideoPreview(selectedFile),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Get the patient and doctor email
              String patientEmail = widget.patientEmail;
              String doctorEmail = widget.doctorEmail;

              // Get the current timestamp
              DateTime now = DateTime.now();
              String timeStamp = now.microsecondsSinceEpoch.toString();
              String fileName;
              // Construct the desired file name
              if (fileType == 'video')
                fileName = 'video_$patientEmail' + '_' + '$doctorEmail' + '_' + timeStamp;
              else{
                fileName = '$patientEmail' + '_' + '$doctorEmail' + '_' + timeStamp;
              }
              // Create a reference to the chatMedia folder in Firebase Storage
              firebase_storage.Reference storageRef =
              firebase_storage.FirebaseStorage.instance.ref().child('chatMedia');

              // Upload the file to Firebase Storage
              try {
                await storageRef.child(fileName).putFile(selectedFile);

                String fileURL = await storageRef.child(fileName).getDownloadURL();

                String sender = widget.patientEmail;

                if (widget.currentUser == 'doctor') {
                  sender = widget.doctorEmail;
                }

                FirebaseFirestore.instance.collection('chats').add({
                  'sender': sender,
                  'message': fileURL,
                  'doctorEmail': widget.doctorEmail,
                  'patientEmail': widget.patientEmail,
                  'timestamp': DateTime.now().toIso8601String(),
                });

              } catch (e) {
                // An error occurred while uploading the file
                print('Error uploading file: $e');
              }
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  Future<String> getRespondentToken(String email) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tokens')
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final document = snapshot.docs[0];
      return document['token'] as String;
    } else {
      // Handle the case where the document is not found or the snapshot is empty
      return ''; // Return an empty string or an appropriate value
    }
  }

  Widget _buildVideoPreview(File videoFile) {
    _videoPlayerController = VideoPlayerController.file(videoFile);
    _initializeVideoPlayerFuture = _videoPlayerController!.initialize();

    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildMessage(String message, String formattedTime, String sender) {
    final isCurrentUser = (widget.currentUser == 'doctor' && sender == widget.doctorEmail) ||
        (widget.currentUser == 'patient' && sender == widget.patientEmail);

    if (message.startsWith('https://firebasestorage.googleapis.com/v0/b/ourhealth-996c6.appspot.com/o/chatMedia%2Fvideo')) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: _buildVideoPlayer(message),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Color(0xFF5D3FD3) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center( child: Text(
                      'Sent a video',
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black,
                      ),
                    ),)
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                formattedTime,
                style: TextStyle(
                   // color: Colors.grey
                ),
              ),
            ],
          ),
        ),
      );
    } else if (message.startsWith('https://firebasestorage.googleapis.com/v0/b/ourhealth-996c6.appspot.com')) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: Image.network(
                message,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Image.network(
                message,
              ),
              SizedBox(height: 8),
              Text(
                formattedTime,
                style: TextStyle(
                   // color: Colors.grey
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Container(
                child: Align(
                  alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                    textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
                  ),
                ),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Color(0xFF5D3FD3) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              formattedTime,
              style: TextStyle(
               //   color: Colors.grey
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
          backgroundColor: Color(0xFF5D3FD3),
        title: Row(
            children: [
              FutureBuilder<String>(
                future: currentUser == 'doctor'
                    ? getPatientProfilePic(widget.patientEmail)
                    : getDoctorProfilePic(widget.doctorEmail),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final profilePic = snapshot.data!;
                    return CircleAvatar(
                      backgroundImage: NetworkImage(profilePic),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
          SizedBox(width: 20),
          FutureBuilder<String>(
          future: getDoctorFullName(widget.doctorEmail),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final doctorFullName = snapshot.data!;
              return FutureBuilder<String>(
                future: getPatientFullName(widget.patientEmail),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final patientFullName = snapshot.data!;
                    return Text(getAppBarTitle(
                      currentUser,
                      "Dr. "+doctorFullName,
                      patientFullName,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                    ));
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Text('Loading...');
                  }
                },
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text('Loading...');
            }
          },
        ),
      ]
      ),

        actions: [
          IconButton(
            onPressed: () async {
              if( currentUser == 'doctor'){
                String name = await getDoctorFullName(widget.doctorEmail);
                NotificationService.sendCallNotification(await getRespondentToken(widget.patientEmail),"Incoming Audio Call","Dr. $name is calling you");
              }
              else if (currentUser == 'patient'){
                String name = await getPatientFullName(widget.patientEmail);
                NotificationService.sendCallNotification(await getRespondentToken(widget.doctorEmail),"Incoming Audio Call","$name is calling you");
              }
              Navigator.push(
                  context,MaterialPageRoute(
                builder: (context) => const callPage(
                  isCaller: true,
                  callType: "Audio call",),
              )
              );

            },
            icon: Icon(Icons.call),
          ),
          IconButton(
            onPressed: () async {
              if( currentUser == 'doctor'){
                String name = await getDoctorFullName(widget.doctorEmail);
                NotificationService.sendCallNotification(await getRespondentToken(widget.patientEmail),"Incoming Video Call","Dr. $name is calling you");
              }
              else if (currentUser == 'patient'){
                print("patient");
                String name = await getPatientFullName(widget.patientEmail);
                NotificationService.sendCallNotification(await getRespondentToken(widget.doctorEmail),"Incoming Video Call","$name is calling you");
              }
              Navigator.push(
                  context,MaterialPageRoute(
                builder: (context) => const callPage(
                    isCaller: true,
                    callType: "Video call",),
              )
              );
            },
            icon: Icon(Icons.video_call),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('doctorEmail', isEqualTo: widget.doctorEmail)
                  .where('patientEmail', isEqualTo: widget.patientEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final chatDocs = snapshot.data!.docs;

                  // Sort the chat messages by timestamp in descending order
                  chatDocs.sort((a, b) {
                    final aTimestamp = DateTime.parse(a['timestamp'] as String);
                    final bTimestamp = DateTime.parse(b['timestamp'] as String);
                    return bTimestamp.compareTo(aTimestamp);
                  });

                  return ListView.builder(
                    reverse: true,
                    itemCount: chatDocs.length,
                    itemBuilder: (context, index) {
                      final chatDoc = chatDocs[index];
                      final message = chatDoc['message'];
                      final timestamp = chatDoc['timestamp'] as String;
                      final sender = chatDoc['sender'] as String;

                      final isCurrentUser = (widget.currentUser == 'doctor' && sender == widget.doctorEmail) ||
                          (widget.currentUser == 'patient' && sender == widget.patientEmail);

                      String formattedTime = DateFormat('h:mm a').format(DateTime.parse(timestamp));
                      String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(timestamp));

                      // Check if a new day has started
                      if (index > 0) {
                        final previousTimestamp = chatDocs[index - 1]['timestamp'] as String;
                        final previousDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(previousTimestamp));
                        if (formattedDate != previousDate) {
                          // Display the date in the center of the screen
                          return Column(
                            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Center(child: Text(formattedDate)),
                              SizedBox(height: 50),
                              _buildMessage(message, formattedTime, sender),
                            ],
                          );
                        }
                      }

                      return _buildMessage(message, formattedTime, sender);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0), // Set the border radius
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: () => _uploadFile('image'),
                  ),
                  IconButton(
                    icon: Icon(Icons.video_library),
                    onPressed: () => _uploadFile('video'),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),

          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    _initializeVideoPlayerFuture = _videoPlayerController!.initialize();

    return AspectRatio(
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return VideoPlayer(_videoPlayerController!);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          IconButton(
            icon: Icon(
              _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_videoPlayerController!.value.isPlaying) {
                  _videoPlayerController!.pause();
                } else {
                  _videoPlayerController!.play();
                }
              });
            },
          ),
        ],
      ),
    );
  }
}