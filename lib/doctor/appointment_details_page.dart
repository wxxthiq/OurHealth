import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ourhealth/doctor/appointment_requests_page.dart';
import 'package:url_launcher/url_launcher.dart';


class AppointmentDetailsPage extends StatelessWidget {
  final Map<String, dynamic>? appointmentData;
  final String doctorEmail;


  AppointmentDetailsPage({this.appointmentData, required this.doctorEmail});

  @override
  Widget build(BuildContext context) {
    final patientName = appointmentData?['patientName'] as String? ?? 'no patient name either';
    final reason = appointmentData?['reason'] as String? ?? 'Reason not provided';
    final appointmentDate = appointmentData?['appointmentDateTime'] as String? ?? 'cannot find appointmentDate';
    final notes = appointmentData?['notes'] as String? ?? '';
    final appointmentLocation = appointmentData?['location'] as String? ?? '';
    final insuranceDocuments =appointmentData?['insuranceDocuments'] as String? ?? '';
    final displayNotes = notes.isNotEmpty ? notes : 'N/A';

    BuildContext dialogContext;

    Future<void> _acceptAppointment(String patientEmail, String doctorEmail) async {
      // Construct the data for the medical history document
      final String appointmentDateTime = appointmentData?['appointmentDateTime'] as String? ?? 'Unknown';
      DateTime dateTime = DateTime.parse(appointmentDateTime);
      String isoDateTime = dateTime.toIso8601String();
      final String mhID =FirebaseFirestore.instance.collection('medicalHistory').doc().id;
print("we accept");
      final medicalHistoryData = {
        'medicalHistoryID': mhID,
        'dateOfIssue': DateTime.now().toIso8601String(), // Use the original dateOfIssue
        'doctorComment': "Appointment Request Accepted", // Use the original doctorComment
        'doctorEmail': doctorEmail,
        'patientEmail': patientEmail,
        'event': reason,
        'prescriptionImageUrl': " ", // Use the original prescriptionImage
      };

      FirebaseFirestore.instance.collection('medicalHistory').doc(mhID).set({
        'medicalHistoryID': mhID,
        'dateOfIssue': DateTime.now().toIso8601String(), // Use the original dateOfIssue
        'doctorComment': "Appointment Request Accepted", // Use the original doctorComment
        'doctorEmail': doctorEmail,
        'patientEmail': patientEmail,
        'event': reason,
        'prescriptionImageUrl': " ", // U
      }).then((value) {
        // Refresh the page
      }).catchError((error) {
        // Show an error snackbar
        print(error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update chat. Please try again.'),
            backgroundColor: Colors.red, // Set the snackbar color to red
          ),
        );
      });

      // Update the medical history documents

      // final batch = FirebaseFirestore.instance.batch();
      // batch.set(FirebaseFirestore.instance.collection('medicalHistory').doc(), medicalHistoryData);
      // print("3 accept");
      // try {
      //   print("4 accept");
      //   await batch.commit();
      //   print("5 accept");
      //   // Show a snackbar
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Medical history updated successfully.'),
      //       backgroundColor: Colors.green, // Set the snackbar color to green
      //     ),
      //   );
      //   // Refresh the page setState(() {});
      // } catch (error) {
      //   // Show an error snackbar
      //   print(error);
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Failed to update medical history. Please try again.'),
      //       backgroundColor: Colors.red, // Set the snackbar color to red
      //     ),
      //   );
      // }


      FirebaseFirestore.instance.collection('appointmentRequests').doc(appointmentData!['id']).update({'status': 'booked'});

      // Generate chat ID
      final chatID = FirebaseFirestore.instance.collection('chats').doc().id;
      print(chatID);
      // Update the chats collection
      FirebaseFirestore.instance.collection('chats').doc(chatID).set({
        'chatID': chatID,
        'patientEmail': patientEmail,
        'doctorEmail': doctorEmail,
        'timestamp': DateTime.now().toIso8601String(),
        'sender': doctorEmail,
        'message': 'Appointment request for '+ medicalHistoryData['event']! + ' has been accepted.',
      }).then((value) {
        // Refresh the page
      }).catchError((error) {
        // Show an error snackbar
        print(error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update chat. Please try again.'),
            backgroundColor: Colors.red, // Set the snackbar color to red
          ),
        );
      });

    }

    String _getMonthName(int month) {
      switch (month) {
        case 1:
          return 'January';
        case 2:
          return 'February';
        case 3:
          return 'March';
        case 4:
          return 'April';
        case 5:
          return 'May';
        case 6:
          return 'June';
        case 7:
          return 'July';
        case 8:
          return 'August';
        case 9:
          return 'September';
        case 10:
          return 'October';
        case 11:
          return 'November';
        case 12:
          return 'December';
        default:
          return 'Unknown';
      }
    }

    String _formatTime(String appointmentDate) {

      final dateTime = DateTime.parse(appointmentDate);
      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final formattedHour = hour.toString().padLeft(2, '0');
      final formattedMinute = minute.toString().padLeft(2, '0');
      return '$formattedHour:$formattedMinute';
    }

    void _submitAccept() async {
      final String patientName = appointmentData?['patientName'] as String? ?? 'Unknown';
      final String facilityName = appointmentData?['facilityName'] as String? ?? 'Unknown';
      final String appointmentDateTime = appointmentData?['appointmentDateTime'] as String? ?? 'Unknown';
      // Query the appointment request document in Firestore
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointmentRequests')
          .where('patientName', isEqualTo: patientName)
          .where('facilityName', isEqualTo: facilityName)
          .where('appointmentDateTime', isEqualTo: appointmentDateTime)
          .get();

      // Update the matching document(s) in Firestore
      for (final doc in snapshot.docs) {
        FirebaseFirestore.instance.collection('appointmentRequests').doc(doc.id).update({
          'status': 'booked',
        });
      }

      dialogContext = context;
      showDialog(
        context: dialogContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Appointment confirmed',
                style: TextStyle(color: Color(0xFF5D3FD3), fontSize: 20, fontWeight: FontWeight.bold)),
            content: Text('Patient has been notified',
                style: TextStyle( fontSize: 14)),
            actions: <Widget>[
              TextButton(
                child: Text('OK',
            style: TextStyle(color: Color(0xFF5D3FD3),)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
    final formattedDateTime = DateTime.parse(appointmentDate!);
    final formattedDate = _getMonthName(formattedDateTime.month) +
        ' ' +
        formattedDateTime.day.toString() +
        ', ' +
        formattedDateTime.year.toString();
    final formattedTime = _formatTime(appointmentDate);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Appointment Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      patientName,
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      reason,
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: appointmentLocation,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {
                              launchMaps(appointmentLocation);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (insuranceDocuments != "")
                 Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional documents',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Additional documents',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {
                              launch(insuranceDocuments);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      notes,
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFF5D3FD3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),

                    onPressed:(){
                     Navigator.pop(context);
                      _acceptAppointment(appointmentData?['patientEmail'], doctorEmail);
                      _submitAccept();
                    },
                    child: Text('Accept'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () {
                     // Navigator.pop(context);
                      _showDeclineReasonPrompt(context);
                    },
                    child: Text('Decline'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeclineReasonPrompt(BuildContext context) {
    String declineReason = '';
    File? image;
    TextEditingController textEditingController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void getImage() async {
              final pickedImage = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (pickedImage != null) {
                setState(() {
                  image = File(pickedImage.path);
                });
              }
            }

            void _clearImage() {
              setState(() {
                image = null;
              });
            }

            bool _isSubmitButtonEnabled() {
              return declineReason.trim().isNotEmpty && textEditingController.text.trim().isNotEmpty;
            }


            void _submitDecline() async {
              final String patientName = appointmentData?['patientName'] as String? ?? 'Unknown';
              final String facilityName = appointmentData?['facilityName'] as String? ?? 'Unknown';
              final String appointmentDateTime = appointmentData?['appointmentDateTime'] as String? ?? 'Unknown';
              final DateTime declineDateTime = DateTime.now();
              final String formattedDateTime = declineDateTime.toString().replaceAll(':', '-');
              final String imageName = '$patientName'+'_$facilityName'+'_$formattedDateTime.jpg';
              final declinePicUrl = await _uploadImage(image, imageName);

              // Query the appointment request document in Firestore
              final QuerySnapshot snapshot = await FirebaseFirestore.instance
                  .collection('appointmentRequests')
                  .where('patientName', isEqualTo: patientName)
                  .where('facilityName', isEqualTo: facilityName)
                  .where('appointmentDateTime', isEqualTo: appointmentDateTime)
                  .get();

              print(declinePicUrl);
              // Update the matching document(s) in Firestore
              for (final doc in snapshot.docs) {
                FirebaseFirestore.instance.collection('appointmentRequests').doc(doc.id).update({
                  'status': 'declined',
                  'declinePic': declinePicUrl,
                  'declineReason': declineReason,
                });
              }
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Appointment has been declined',
                        style: TextStyle(color: Color(0xFF5D3FD3), fontSize: 20, fontWeight: FontWeight.bold)),
                    content: Text('Patient has been notified',
                        style: TextStyle( fontSize: 14)),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          // Navigate back to the AppointmentRequestsPage
                          Navigator.pop(context);

                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => AppointmentRequestsPage(healthcareFacility: facilityName, doctorEmail: doctorEmail,)),
                          // );
                        },
                      ),
                    ],
                  );
                },
              );


            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decline Appointment Request',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        IconButton(
                          onPressed: getImage,
                          icon: Icon(Icons.image),
                        ),
                        Expanded(
                          child: TextField(
                            controller: textEditingController,
                            decoration: InputDecoration(
                              labelText: 'Provide reason for the decline',
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              declineReason =value;
                              setState(() {}); // Update the UI when the text field changes
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (image != null) Image.file(image!, height: 100),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (image != null)
                          TextButton(
                            onPressed: _clearImage,
                            child: Text(
                              'Clear Image',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          onPressed: _isSubmitButtonEnabled() ? _submitDecline : null,
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _uploadImage(File? image, String imageName) async {
    if (image == null) {
      return ''; // Return empty string if no image is selected
    }

    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final Reference ref = storage.ref().child('appointmentDeclineImages/$imageName');
      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
      final String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  void launchMaps(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch Maps';
    }
  }

}
