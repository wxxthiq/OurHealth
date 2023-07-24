import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ourhealth/pages/home_page.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../helper/helper_function.dart';
import '../widgets/widgets.dart';
import 'dart:io';

class appointmentBookingPage extends StatefulWidget {
  final String facilityName;
  final String location;
  final String patientLocation;
  final String facilityAddress;

  appointmentBookingPage({
    required this.facilityName,
    required this.location,
    required this.patientLocation,
    required this.facilityAddress,
  });

  @override
  _AppointmentBookingPageState createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<appointmentBookingPage> {
  TextEditingController notesController = TextEditingController();
  TextEditingController dateTimeController = TextEditingController();
  String patientEmail = "";
  String patientName = "";
  String selectedReason = "";
  String uploadedFileName = "";
  String uploadedFilePath="";
  String insuranceDocuments ="";

  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  final List<String> reasons = [
    'Consultation',
    'Follow-Up Appointment',
    'Injury',
    'Illness',
    'Medical Check Up',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    gettingUserData();
    selectedReason = reasons[0];
  }

  gettingUserData() async {
    await HelperFunctions.getUserName().then((value) {
      setState(() {
        patientName = value!;
      });
    });

    await HelperFunctions.getUserEmail().then((value) {
      setState(() {
        patientEmail = value!;
      });
    });

  }

  String getAppointmentLocation() {
    if (widget.location == "Healthcare Facility") {
      return widget.facilityAddress;
    }
    else{
      return widget.patientLocation;
    }
  }

  Future<void> _pickAndUploadAdditionalDocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      List<PlatformFile> files = result.files;

      setState(() {
        uploadedFileName = files[0].name ?? '';
        uploadedFilePath = files[0].path ?? '';
      });

    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF5D3FD3),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
            colorScheme: ColorScheme.light(primary: Color(0xFF5D3FD3)).copyWith(secondary: Color(0xFF5D3FD3)),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: Color(0xFF5D3FD3),
              buttonTheme: ButtonThemeData(
                textTheme: ButtonTextTheme.primary,
              ),
              colorScheme: ColorScheme.light(primary: Color(0xFF5D3FD3)).copyWith(secondary: Color(0xFF5D3FD3)),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        final DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          dateTimeController.text = DateFormat("yyyy-MM-dd HH:mm").format(selectedDateTime);
        });
      }
    }
  }

  bool validateFields() {
    if (selectedReason.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Validation Error'),
          content: Text('Please select a reason for the visit.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    if (dateTimeController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Validation Error'),
          content: Text('Please select a date and time for the visit.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text(widget.facilityName),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.0),
              GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Healthcare Facility',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        widget.facilityName,
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.0),
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
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                    ),
                    SizedBox(height: 15.0),
                    Text(
                      getAppointmentLocation(),
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
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
                      "Reason for Visit",
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: textInputDecoration.copyWith(
                        hintText: "Select reason",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      items: reasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedReason = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
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
                      "Date and Time of Visit",
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                    ),
                    GestureDetector(
                      onTap: () => _showDatePicker(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: dateTimeController,
                          decoration: textInputDecoration.copyWith(
                            hintText: "Select date and time",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
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
                      "Additional documents",
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                    ),
                    SizedBox(height: 20),
                    if (uploadedFileName.isNotEmpty)
                      Text(
                      "Currently Uploaded - $uploadedFileName", // Display the uploaded file name
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                    ),
                    SizedBox(height: 20),

                    Center(
                      child: ElevatedButton(
                        onPressed: _pickAndUploadAdditionalDocuments,
                        child: Text('Upload Additional Documents'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
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
                      "Additional Notes",
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                    ),
                    TextField(
                      controller: notesController,
                      decoration: textInputDecoration.copyWith(
                        hintText: "Enter more details about the reason of visit or any relevant details regarding the appointment",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    if (validateFields()) {
                      // Access the entered values using the respective TextEditingController instances
                      final String reason = selectedReason;
                      final String dateTime = dateTimeController.text;
                      final String notes = notesController.text;

                      // Create an appointment request document in Firestore
                      try {
                        final appointmentRef =
                        FirebaseFirestore.instance.collection('appointmentRequests').doc();
                        final String appointmentID = Uuid().v4();

                        // Upload the file to Firebase Storage
                        if (uploadedFileName.isNotEmpty) {
                          // Generate a unique filename for the uploaded file
                          final String fileName = '$appointmentID-${uploadedFileName.replaceAll(' ', '_')}';

                          // Create a reference to the file in Firebase Storage
                          final firebase_storage.Reference storageRef =
                          storage.ref().child('insuranceDocuments/$fileName');

                          // Upload the file
                          final firebase_storage.UploadTask uploadTask =
                          storageRef.putFile(File(uploadedFilePath));

                          // Get the download URL of the uploaded file
                          final firebase_storage.TaskSnapshot taskSnapshot =
                          await uploadTask.whenComplete(() {});

                          if (taskSnapshot.state == firebase_storage.TaskState.success) {
                            final String downloadURL =
                            await taskSnapshot.ref.getDownloadURL();
                            // Store the download URL in the insuranceDocuments variable
                            insuranceDocuments = downloadURL;
                          }
                        }
//print(insuranceDocuments);
                        await appointmentRef.set({
                          'insuranceDocuments': insuranceDocuments,
                          'patientName': patientName,
                          'patientEmail': patientEmail,
                          'facilityName': widget.facilityName,
                          'location': getAppointmentLocation(),
                          'reason': selectedReason,
                          'appointmentDateTime': dateTime,
                          'notes': notes,
                          'status': 'pending',
                          'declinePic': '',
                          'declineReason': '',
                          'cancelReason': '',
                          'appointmentID': appointmentID,
                        });

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Appointment Request'),
                            content: Text('Your appointment request has been submitted successfully.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  nextScreenReplace(context, HomePage());
                                },
                                child: Text('Thank You',
                                    style: TextStyle(color:Color(0xFF5D3FD3) )),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        // Show an error message to the user
                        print('Error: $e'); // Print the error message
                     //   print('StackTrace: ${e.stackTrace}'); // Print the stack trace
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Error'),
                            content: Text('Failed to submit appointment request. Please try again.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    "Book Appointment",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
