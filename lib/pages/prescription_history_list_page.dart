import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/pages/patient_activities_page.dart';
import 'package:intl/intl.dart';

class prescriptionHistoryListPage extends StatelessWidget {
  final String email;

  const prescriptionHistoryListPage({Key? key, required this.email}) : super(key: key);

  Future<String> getPharmacistName(String doctorEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pharmacists')
        .where('email', isEqualTo: doctorEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final document = snapshot.docs[0];
      return document['fullName'] as String;
    } else {
      return ''; // Return an empty string or an appropriate value
    }
  }

  Future<String> getPharmacyName(String doctorEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pharmacists')
        .where('email', isEqualTo: doctorEmail)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final document = snapshot.docs[0];
      return document['pharmacyName'] as String;
    } else {
      return ''; // Return an empty string or an appropriate value
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Prescription History List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medicalHistory')
            .where('patientEmail', isEqualTo: email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final medicalHistoryDocs = snapshot.data!.docs;

            if (medicalHistoryDocs.isEmpty) {
              // Display text when no records are found
              return Center(
                child: Text(
                  'No medical activity to track',
                  style: TextStyle(fontSize: 20, color: Color(0xFF5D3FD3)),
                ),
              );
            }

            final Map<String, dynamic> latestMedicalHistory = {};

            for (final medicalHistoryDoc in medicalHistoryDocs) {
              final medicalHistoryID = medicalHistoryDoc['medicalHistoryID'] as String;
              final dateOfIssue = medicalHistoryDoc['dateOfIssue'] as String;

              final latestEntry = latestMedicalHistory[medicalHistoryID];
              if (latestEntry == null || dateOfIssue.compareTo(latestEntry['dateOfIssue']) > 0) {
                latestMedicalHistory[medicalHistoryID] = medicalHistoryDoc.data();
              }
            }

            final uniqueMedicalHistoryDocs = latestMedicalHistory.values.toList();

            return ListView.builder(
              itemCount: uniqueMedicalHistoryDocs.length,
              itemBuilder: (context, index) {
                final medicalHistoryDoc = uniqueMedicalHistoryDocs[index];
                final mhID = medicalHistoryDoc['medicalHistoryID'] ?? 'Unknown Medical History ID';
                final patientEmail = medicalHistoryDoc['patientEmail'] ?? 'Unknown Medical History ID';
                final doctorEmail = medicalHistoryDoc['doctorEmail'] ?? 'Unknown Medical History ID';
                final event = medicalHistoryDoc['event'] ?? 'Unknown Event';
                final dateOfIssue = DateTime.parse(medicalHistoryDoc['dateOfIssue']);
                final formattedDate = DateFormat('dd MMMM yyyy').format(dateOfIssue);
                final formattedTime = DateFormat('h:mm a').format(dateOfIssue);


                return FutureBuilder<String>(
                  future: getPharmacistName(doctorEmail),
                  builder: (context, pharmacistSnapshot) {
                    if (pharmacistSnapshot.connectionState == ConnectionState.waiting) {
                      // Display a loading indicator while waiting for the pharmacist name result
                      return CircularProgressIndicator();
                    } else if (pharmacistSnapshot.hasError) {
                      // Handle the error case
                      return Text('Error: ${pharmacistSnapshot.error}');
                    } else {
                      final pharmacistName = pharmacistSnapshot.data ?? '';

                      return FutureBuilder<String>(
                        future: getPharmacyName(doctorEmail),
                        builder: (context, pharmacySnapshot) {
                          if (pharmacySnapshot.connectionState == ConnectionState.waiting) {
                            // Display a loading indicator while waiting for the pharmacy name result
                            return CircularProgressIndicator();
                          } else if (pharmacySnapshot.hasError) {
                            // Handle the error case
                            return Text('Error: ${pharmacySnapshot.error}');
                          } else {
                            final pharmacyName = pharmacySnapshot.data ?? '';

                            if (pharmacyName.isNotEmpty) {
                              return GestureDetector(
                                onTap: () {
                                  // Handle the tap event and navigate to another page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => patientActivitiesPage(
                                        doctorEmail: doctorEmail,
                                        patientEmail: patientEmail,
                                        medicalHistoryID: mhID,
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  child: ListTile(
                                    title: Text(
                                      pharmacyName,
                                      style: TextStyle(
                                        color: Color(0xFF5D3FD3),
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          event,
                                          style: TextStyle(color: Colors.black, fontSize: 16),
                                        ),
                                        Text(
                                          '$formattedDate - $formattedTime',
                                          style: TextStyle(color: Colors.black, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios),
                                  ),
                                ),
                              );
                            } else {
                              // Skip the entry if it is a doctor
                              return SizedBox.shrink();
                            }
                          }
                        },
                      );
                    }
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
