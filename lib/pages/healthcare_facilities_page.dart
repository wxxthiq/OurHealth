import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geodesy/geodesy.dart';
import 'healthcare_facility_details_page.dart';

class HealthFacilitiesPage extends StatefulWidget {
  final String userLocation;
  final double distancePreference;
  final String specialization;
  final String insuranceProvider;
  final String appointmentLocation;

  HealthFacilitiesPage({
    required this.userLocation,
    required this.distancePreference,
    required this.specialization,
    required this.insuranceProvider,
    required this.appointmentLocation,
  });

  @override
  _HealthFacilitiesPageState createState() => _HealthFacilitiesPageState();
}

class _HealthFacilitiesPageState extends State<HealthFacilitiesPage> {
  List<Map<String, dynamic>> facilityDataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getFacilities();
  }


  Future<void> getFacilities() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('healthcareFacilities').get();
    setState(() {
      facilityDataList.clear();
      isLoading = true;
    });

    bool hasFacilityFound = false;

    for (DocumentSnapshot document in snapshot.docs) {
      String facilityAddress = document['address'];
      String facilityPic = document['facilityPic'];
      String contactNumber = document['phoneNumber'];
      String website = document['website'];

      dynamic operationHoursField = document['operationHours'];
      dynamic specializationField = document['specialization'];
      dynamic insuranceProviderField = document['insuranceProviders'];
      bool homeAppointments = document['homeAppointments'];

      List<String> operationHours = (operationHoursField is List) ? List<String>.from(operationHoursField) : [(operationHoursField as String)];
      List<String> specializations = (specializationField is List) ? List<String>.from(specializationField) : [(specializationField as String)];
      List<String> insuranceProviders = (insuranceProviderField is List) ? List<String>.from(insuranceProviderField) : [(insuranceProviderField as String)];

      if ((widget.specialization == 'Any' || specializations.contains(widget.specialization)) &&
          (widget.insuranceProvider == 'Any' || insuranceProviders.contains(widget.insuranceProvider))) {
        List<Location> facilityLocations = await locationFromAddress(facilityAddress);
        List<Location> userLocations = await locationFromAddress(widget.userLocation);

        if (facilityLocations.isNotEmpty && userLocations.isNotEmpty) {
          Location facilityLocation = facilityLocations.first;
          Location userLocation = userLocations.first;

          Geodesy geodesy = Geodesy();
          num distanceInMeters = geodesy.distanceBetweenTwoGeoPoints(
            LatLng(userLocation.latitude!, userLocation.longitude!),
            LatLng(facilityLocation.latitude!, facilityLocation.longitude!),
          );

          String distance = '${(distanceInMeters / 1000).toStringAsFixed(2)} km';

          if ((widget.appointmentLocation == '' ||
              (widget.appointmentLocation == 'My Location' && homeAppointments) ||
              (homeAppointments) ||
              (widget.appointmentLocation == 'Healthcare Facility' && !homeAppointments)) &&
              distanceInMeters <= widget.distancePreference * 1000) {
            Map<String, dynamic> facilityData = {
              'name': document['name'],
              'address': facilityAddress,
              'facilityPic': facilityPic,
              'operationHours': operationHours,
              'contactNumber': contactNumber,
              'website': website,
              'distance': distance,
            };

            setState(() {
              facilityDataList.add(facilityData);
              facilityDataList.sort((a, b) => a['distance'].compareTo(b['distance']));
              isLoading = false;
              hasFacilityFound = true;
            });
          }
        }
      }
    }

    if (!hasFacilityFound) {
      setState(() {
        isLoading = false;
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Healthcare Facilities'),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(), // Display a loading indicator
      )
          : facilityDataList.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No healthcare facility found\n Update the filter for more results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        itemCount: facilityDataList.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> facilityData = facilityDataList[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FacilityDetailsPage(
                facilityName: facilityData['name'] ?? '',
                facilityPicture: facilityData['facilityPic'] ?? '',
                operationHours: facilityData['operationHours'] ?? '',
                facilityAddress: facilityData['address'] ?? '',
                contactNumber: facilityData['contactNumber'] ?? '',
                website: facilityData['website'] ?? '',
                      patientLocation: widget.userLocation,
                appointmentLocation: widget.appointmentLocation,
                  pharmacySearch: false,),

                ),
              );
            },
            child: ListTile(
              title: Text(
                facilityData['name'],
                style: TextStyle(
                  color: Color(0xFF5D3FD3),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Distance: ${facilityData['distance']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}
