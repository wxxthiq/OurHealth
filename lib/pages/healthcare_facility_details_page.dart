import 'package:maps_launcher/maps_launcher.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/pages/appointment_booking_page.dart';
import 'package:ourhealth/pages/prescription_refill_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class FacilityDetailsPage extends StatelessWidget {

  final String facilityName;
  final String facilityPicture; // Assuming the picture URL is stored in the database
  final List<String> operationHours;
  final String facilityAddress;
  final String contactNumber;
  final String website;
  final String appointmentLocation;
  final String patientLocation;
  final bool pharmacySearch;

  FacilityDetailsPage({
    required this.facilityName,
    required this.facilityPicture,
    required this.operationHours,
    required this.facilityAddress,
    required this.contactNumber,
    required this.website,
    required this.appointmentLocation,
    required this.patientLocation,
    required this.pharmacySearch,
  });

  Future<void> _launchWebsite(String url) async {
    final String completeUrl = "$url"; // Add the scheme (https://) to the URL
    if (!await launchUrl(
      Uri.parse(completeUrl),
      mode: LaunchMode.externalApplication,
    )) {
      throw "Cannot launch URL";
    }
  }

  Future<void> _launchCaller(String number) async {
    final Uri uri = Uri(scheme: "tel", path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw "Can not reach phone number";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Set the background color of the page
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text(facilityName),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0), // Set the desired padding
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                height: 300,
                child: Center(
                  child: facilityPicture != null && facilityPicture.isNotEmpty
                      ? Image.network(
                    facilityPicture,
                    fit: BoxFit.cover,
                  )
                      : Image.network(
                    'https://example.com/default-image.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              //SizedBox(height: 16.0),
              // Operation hours
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0), // Apply round borders
                ),
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operation Hours',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      operationHours.join("\n"),
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.0),
              // Address
              GestureDetector(
                onTap: () => MapsLauncher.launchQuery(facilityAddress),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0), // Apply round borders
                  ),
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        facilityAddress,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              // Contact number
              GestureDetector(
                onTap: () => _launchCaller(contactNumber),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0), // Apply round borders
                  ),
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Number',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF5D3FD3)),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        contactNumber,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              // Website
              GestureDetector(
                onTap: () => _launchWebsite(website),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0), // Apply round borders
                  ),
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Website',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold ,color: Color(0xFF5D3FD3)),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        website,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 60.0),
              if (appointmentLocation.isNotEmpty && !pharmacySearch)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),

                  child: const Text(
                    "Book Appointment",
                    style: TextStyle(color: Colors.white, fontSize:16),
                  ),
                   onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => appointmentBookingPage(
                        facilityName: facilityName,
                        location: appointmentLocation,
                        patientLocation: patientLocation,
                      facilityAddress: facilityAddress,),
                      ),
                    );
                   },
                ),
              if (pharmacySearch)
                Row(
                  children :[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))),

                        child: const Text(
                          "Prescription Pick Up",
                          style: TextStyle(color: Colors.white, fontSize:16),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PrescriptionRefillPage(
                              facilityName: facilityName,
                              location: appointmentLocation,
                              patientLocation: patientLocation,
                              facilityAddress: facilityAddress,
                              requestType: "Pick Up",),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width:16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))),
                        child: const Text(
                          "Prescription Delivery",
                          style: TextStyle(color: Colors.white, fontSize:16),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PrescriptionRefillPage(
                              facilityName: facilityName,
                              location: appointmentLocation,
                              patientLocation: patientLocation,
                              facilityAddress: facilityAddress,
                              requestType: "Delivery",),
                            ),
                          );
                        },
                      ),
                    ),
                  ]
                )
            ],
          ),
        ),
      ),
    );
  }
}