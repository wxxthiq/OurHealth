import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ourhealth/pages/home_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import '../helper/helper_function.dart';
import '../widgets/widgets.dart';

class PrescriptionRefillPage extends StatefulWidget {
  final String facilityName;
  final String location;
  final String patientLocation;
  final String facilityAddress;
  final String requestType;

  PrescriptionRefillPage({
    required this.facilityName,
    required this.location,
    required this.patientLocation,
    required this.facilityAddress,
    required this.requestType,
  });

  @override
  _PrescriptionRefillPageState createState() => _PrescriptionRefillPageState();
}

class _PrescriptionRefillPageState extends State<PrescriptionRefillPage> {
  TextEditingController notesController = TextEditingController();
  TextEditingController dateTimeController = TextEditingController();
  String patientEmail = "";
  String patientName = "";
  File? prescriptionFile;


  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  gettingUserData() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
    print(statuses[Permission.location]);

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

  String getRequestlocation() {
    if (widget.requestType == "Delivery") {
      return  widget.patientLocation;
    }
    else{
      print("facilityName:");
      print(widget.facilityName);
      return widget.facilityName;
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

  bool validateDate() {
    if (dateTimeController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Missing Date / Time'),
          content: Text('Please select a date and time for the delivery / pick up'),
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
                        'Pharmacy / Drug store',
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
              if (widget.requestType != "Pick Up") // Add this condition
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
                      widget.requestType+' location',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                    ),
                    SizedBox(height: 15.0),
                    Text(
                      getRequestlocation(),
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
                      "Date and Time of "+widget.requestType,
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
              if (prescriptionFile != null)
                Center(
                  child: Image.file(prescriptionFile!),
                ),

              SizedBox(height: 20.0),

              Center(
                child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5D3FD3), // Background color
                ),
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                  if (image != null) {
                    setState(() {
                      prescriptionFile = File(image.path);
                    });
                  }
                },
                child: Text('Upload Prescription'),
              ),),
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
                        hintText: "Enter more details about the medication prescribed if necessary.",
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
                    if (validateDate()) {
                      // Access the entered values using the respective TextEditingController instances
                      final String dateTime = dateTimeController.text;
                      final String notes = notesController.text;

                      // Create a prescription request document in Firestore
                      try {
                        final requestRef = FirebaseFirestore.instance.collection('prescriptionRequests').doc();
                        final String requestID = Uuid().v4();
                        // Upload the prescription image to Firebase Storage
                        if (prescriptionFile != null) {
                          String fileName = '${Uuid().v4()}_${prescriptionFile!
                              .path
                              .split('/')
                              .last}';
                          firebase_storage.Reference storageRef = firebase_storage.FirebaseStorage
                              .instance.ref('prescriptionRequests/$fileName');
                          await storageRef.putFile(prescriptionFile!);

                          // Get the download URL
                          String downloadUrl = await storageRef.getDownloadURL();
print("lookf");
                          print(getRequestlocation());
                          await requestRef.set({
                            'patientName': patientName,
                            'patientEmail': patientEmail,
                            'facilityName': widget.facilityName,
                            'requestDateTime': dateTime,
                            'prescriptionUrl': downloadUrl,
                            'notes': notes,
                            'status': 'pending',
                            'declinePic': '',
                            'declineReason': '',
                            'cancelReason': '',
                            'requestID': requestID,
                            'requestLocation': getRequestlocation(),
                          //  'requestLocation': getRequestlocation(),
                          });
                        }
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Prescription Request'),
                            content: Text('Your prescription request has been submitted successfully.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        // Show an error message to the user
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Error'),
                            content: Text('Failed to submit prescription request. Please try again.'),
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
                    "Confirm "+widget.requestType,
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
