import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


class patientActivitiesPage extends StatefulWidget {
  final String doctorEmail;
  final String patientEmail;
  final String medicalHistoryID;

  const patientActivitiesPage({Key? key, required this.doctorEmail,
    required this.patientEmail,
    required this.medicalHistoryID,})
      : super(key: key);

  @override
  _MedicalActivityPageState createState() => _MedicalActivityPageState();
}

class _MedicalActivityPageState extends State<patientActivitiesPage> {

  String medicalHistoryID = "";

  void _openImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Medical Activity'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicalHistory')
                  .where('doctorEmail', isEqualTo: widget.doctorEmail)
                  .where('patientEmail', isEqualTo: widget.patientEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final medicalHistoryDocs = snapshot.data!.docs;
                  medicalHistoryDocs.sort((a, b) => a['dateOfIssue'].compareTo(b['dateOfIssue']));

                  return ListView.builder(
                    itemCount: medicalHistoryDocs.length,
                    itemBuilder: (context, index) {
                      final medicalHistoryDoc = medicalHistoryDocs[index];
                      final event = medicalHistoryDoc['event'];
                      medicalHistoryID = medicalHistoryDoc['medicalHistoryID'];
                      final dateOfIssue = DateTime.parse(medicalHistoryDoc['dateOfIssue']);
                      final doctorComments = medicalHistoryDoc['doctorComment'];
                      final prescriptionImageUrl = medicalHistoryDoc['prescriptionImageUrl'];

                      if(medicalHistoryID == widget.medicalHistoryID)
                         return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF5D3FD3), // Color of the line
                                  ),
                                  child: SizedBox(
                                    width: 4, // Width of the line
                                  ),
                                ),
                              ),

                              Padding(
                                padding: EdgeInsets.only(left: 13), // Add padding here
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5D3FD3),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      DateFormat('d MMMM yyyy - h:mm a').format(dateOfIssue),
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      doctorComments,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    if (prescriptionImageUrl!=" ")
                                      GestureDetector(
                                        onTap: () => _openImage(prescriptionImageUrl),
                                        child: Image.network(
                                          prescriptionImageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      else {
                        return SizedBox(); // Return an empty SizedBox if the condition is not met
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
          ),
        ],
      ),
    );
  }
}
