import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../widgets/widgets.dart';

class MedicalActivityPage extends StatefulWidget {
  final String doctorEmail;
  final String patientEmail;
  final String medicalHistoryID;

  const MedicalActivityPage({
    Key? key,
    required this.doctorEmail,
    required this.patientEmail,
    required this.medicalHistoryID,
  }) : super(key: key);

  @override
  _MedicalActivityPageState createState() => _MedicalActivityPageState();
}

class _MedicalActivityPageState extends State<MedicalActivityPage> {
  TextEditingController _eventPromptController = TextEditingController();
  TextEditingController _commentsPromptController = TextEditingController();
  // Add more necessary controllers for the prompt dialog fields
  File? _selectedPrescriptionImage; // Declare the member variable here

  String _prescriptionImageUrl = ''; // Store the URL of the uploaded image
  String medicalHistoryID = "";
  bool doctorEmailExists = false;
  bool exists = false;
  @override
  void initState() {
    super.initState();
    getDoctorEmail();
  }

  Future<void> getDoctorEmail() async {
    exists = await checkEmailExists(widget.doctorEmail);
    setState(() {});
  }
  Future<String> _uploadPrescriptionImage() async {
    if ( _selectedPrescriptionImage == null) {
      return ' '; // No image to upload, return an empty string
    }

    final storageRef = FirebaseStorage.instance.ref().child('prescription');
    final currentDate = DateTime.now();
    final dateOfIssue = DateFormat('yyyy-MM-dd_HH:mm:ss').format(currentDate);
    final fileName = '$dateOfIssue{widget.patientEmail}_${widget.doctorEmail}.jpg';
    final uploadTask = storageRef.child(fileName).putFile(_selectedPrescriptionImage !);

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    setState(() {
      _prescriptionImageUrl = downloadUrl; // Update the URL with the new value
    });

    return downloadUrl; // Return the download URL
  }

  Future<bool> checkEmailExists(String doctorEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: doctorEmail)
        .get();
    return snapshot != null && snapshot.docs.isNotEmpty;
  }

  void _openImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _showUpdatePrompt() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void getImage() async {
              final pickedImage = await ImagePicker().getImage(
                source: ImageSource.gallery,
              );
              if (pickedImage != null) {
                setState(() {
                  _selectedPrescriptionImage = File(pickedImage.path);
                });
              }
            }

            return Container(
              width: 800,
            child: AlertDialog(
              title: Text('Update Medical History', style: TextStyle(
              color:  Color(0xFF5D3FD3),
            )),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _eventPromptController,
                    decoration: textInputDecoration.copyWith(
                      labelText: "Event / Acitivty details",
                      prefixIcon: Icon(
                          Icons.update,
                          color: Theme.of(context).primaryColor
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _commentsPromptController,
                    decoration: textInputDecoration.copyWith(
                      labelText: "Doctor's comment",
                      prefixIcon: Icon(
                          Icons.comment,
                          color: Theme.of(context).primaryColor
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_selectedPrescriptionImage != null)
                    Image.file(_selectedPrescriptionImage!, height: 100),

                  if (_selectedPrescriptionImage != null)
                    ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFF5D3FD3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () {
                        setState(() {
                          _selectedPrescriptionImage = null;
                        });
                    },
                    child: Text('Remove Prescription'),
                  ),
                  if(_selectedPrescriptionImage == null && exists)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF5D3FD3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      onPressed: () {
                        getImage();
                      },
                      child: Text('Upload Prescription'),
                    ),

                  // Display the selected image if available
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    final downloadUrl = await _uploadPrescriptionImage();
                    final currentDate = DateTime.now().toIso8601String();

                    FirebaseFirestore.instance.collection('medicalHistory').add({
                      'patientEmail': widget.patientEmail,
                      'doctorEmail': widget.doctorEmail,
                      'event': _eventPromptController.text,
                      'medicalHistoryID': medicalHistoryID,
                      'doctorComment': _commentsPromptController.text,
                      'dateOfIssue': currentDate,
                      'prescriptionImageUrl': downloadUrl,
                    });
                    Navigator.pop(context); // Close the dialog
                  },
                  child: Text('Update'),
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF5D3FD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPrescriptionImage = null; // Reset the image selection
                    });
                    Navigator.pop(context); // Close the dialog
                  },
                  child: Text('Cancel',style: TextStyle(
                    color: Colors.white,
                  )),
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF5D3FD3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
            );
          },
        );
      },
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
                      final prescriptionImageUrl =
                      medicalHistoryDoc['prescriptionImageUrl'];


                      if (medicalHistoryID == widget.medicalHistoryID) {
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
                                      SizedBox(height: 20),
                                      Text(
                                        doctorComments,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 30),
                                      if (prescriptionImageUrl!= " " )
                                        Image.network(
                                          prescriptionImageUrl,
                                            fit: BoxFit.cover,
                                          ),

                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {

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
          ButtonBar(
            children: [
              Container(
                alignment: Alignment.center,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Color(0xFF5D3FD3)), // Set the desired color
                  ),
                  onPressed: () {
                    _showUpdatePrompt();
                    //_showDeclineReasonPrompt(context);
                  },
                  child: Text('Update Medical History'),
                ),
              ),
              // Add SizedBox to give spacing below the button if needed
              SizedBox(height: 100, width: 100),
            ],
          ),
        ],
      ),
    );
  }

}
