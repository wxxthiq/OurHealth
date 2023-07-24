import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../doctor/doctor_chat_page.dart';

class patientChatsPage extends StatefulWidget {
  final String patientEmail;

  const patientChatsPage({Key? key, required this.patientEmail}) : super(key: key);

  @override
  _PatientChatsPageState createState() => _PatientChatsPageState();
}

class _PatientChatsPageState extends State<patientChatsPage> {
  String formatDate(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final formattedDate = DateFormat('d MMMM yyyy - h:mm a').format(dateTime);
    return formattedDate;
  }

  Future<DocumentSnapshot?> getDoctorData(String doctorEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: doctorEmail)
        .get();
    if (snapshot.size > 0) {
      return snapshot.docs.first;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Chat with your doctors'),
      ),
      backgroundColor: Color(0xFFECEFF1),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('patientEmail', isEqualTo: widget.patientEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final chats = snapshot.data!.docs;
            if (chats.isEmpty) {
              return Center(child: Text('No chats found'));
            }

            QueryDocumentSnapshot latestChatDoc = chats.first;
            DateTime latestTimestamp = DateTime.parse(latestChatDoc['timestamp']);

            for (final chatDoc in chats) {
              final chatTimestamp = DateTime.parse(chatDoc['timestamp']);
              if (chatTimestamp.isAfter(latestTimestamp)) {
                latestChatDoc = chatDoc;
                latestTimestamp = chatTimestamp;
              }
            }

            final doctorEmail = latestChatDoc['doctorEmail'];

            return FutureBuilder<DocumentSnapshot?>(
              future: getDoctorData(doctorEmail),
              builder: (context, doctorDataSnapshot) {
                if (doctorDataSnapshot.hasData) {
                  final doctorData = doctorDataSnapshot.data;
                  if (doctorData != null) {
                    final doctorName = doctorData.get('fullName');
                    final profilePicUrl = doctorData.get('profilePic');

                    final lastMessageTimestamp = latestChatDoc['timestamp'];
                    final formattedDate = formatDate(lastMessageTimestamp);
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.15,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(profilePicUrl),
                                    radius: 24,
                                  ),
                                  SizedBox(width: 30),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          'Dr.' + doctorName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          latestChatDoc['message'].length > 25
                                              ? latestChatDoc['message'].substring(0, 25) + '...'
                                              : latestChatDoc['message'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF5D3FD3),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: IconButton(
                                      icon: Icon(Icons.chat),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => chatPage(
                                              doctorEmail: doctorEmail,
                                              patientEmail: widget.patientEmail,
                                              currentUser: 'patient',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                    );

                  } else {
                    return Text('Doctor document not found');
                  }
                } else if (doctorDataSnapshot.hasError) {
                  return Text('Error: ${doctorDataSnapshot.error}');
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
