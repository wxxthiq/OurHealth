import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourhealth/doctor/doctor_activity_page.dart';

import '../doctor/doctor_chat_page.dart';


class pharmacyManagePatientsPage extends StatefulWidget {
  final String doctorEmail;

  const pharmacyManagePatientsPage({Key? key, required this.doctorEmail}) : super(key: key);

  @override
  _ManagePatientsPageState createState() => _ManagePatientsPageState();
}

class _ManagePatientsPageState extends State<pharmacyManagePatientsPage> {
  String formatDate(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final formattedDate = DateFormat('d MMMM yyyy - h:mm a').format(dateTime);
    return formattedDate;
  }

  Future<DocumentSnapshot?> getPatientData(String patientEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: patientEmail)
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
        title: Text('Customer list'),
      ),
      backgroundColor: Color(0xFFECEFF1),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medicalHistory')
            .where('doctorEmail', isEqualTo: widget.doctorEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final patients = snapshot.data!.docs;
            final medicalHistoryIds = Set<String>();
            final filteredPatients = <QueryDocumentSnapshot>[];

            for (final patient in patients) {
              final medicalHistoryId = patient['medicalHistoryID'];
              if (!medicalHistoryIds.contains(medicalHistoryId)) {
                medicalHistoryIds.add(medicalHistoryId);
                filteredPatients.add(patient);
              }
            }


            return ListView.separated(
              itemCount: filteredPatients.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final patientDoc = filteredPatients[index];

                return FutureBuilder<DocumentSnapshot?>(
                  future: getPatientData(patientDoc['patientEmail']),
                  builder: (context, patientDataSnapshot) {
                    if (patientDataSnapshot.hasData) {
                      final patientData = patientDataSnapshot.data;
                      if (patientData != null) {
                        final patientName = patientData.get('fullName');
                        final profilePicUrl = patientData.get('profilePic');


                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(profilePicUrl),
                                    radius: 24,
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          patientName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          patientDoc['event'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF5D3FD3),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          formatDate(patientDoc['dateOfIssue']),
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: IconButton(
                                      icon: Icon(Icons.chat),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => chatPage(
                                              doctorEmail: widget.doctorEmail,
                                              patientEmail: patientDoc['patientEmail'],
                                              currentUser: 'doctor',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: IconButton(
                                      icon: Icon(Icons.update),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MedicalActivityPage(
                                              doctorEmail: widget.doctorEmail,
                                              patientEmail: patientDoc['patientEmail'],
                                              medicalHistoryID: patientDoc['medicalHistoryID'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Text('Patient document not found');
                      }
                    } else if (patientDataSnapshot.hasError) {
                      return Text('Error: ${patientDataSnapshot.error}');
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                );
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
