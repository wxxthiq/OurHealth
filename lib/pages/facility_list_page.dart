import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_excel/excel.dart';
import 'package:geocoding/geocoding.dart' as Geocoding;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:string_similarity/string_similarity.dart';
import 'healthcare_facility_details_page.dart';
import 'package:google_maps_webservice/places.dart';

class facilityListPage extends StatefulWidget {
  final String userLocation;
  final double distancePreference;
  final String specialization;
  final String insuranceProvider;
  final String appointmentLocation;

  facilityListPage({
    required this.userLocation,
    required this.distancePreference,
    required this.specialization,
    required this.insuranceProvider,
    required this.appointmentLocation,
  });

  @override
  _HealthFacilitiesPageState createState() => _HealthFacilitiesPageState();
}

class _HealthFacilitiesPageState extends State<facilityListPage> {
  List<Map<String, dynamic>> facilityDataList = [];
  final places = GoogleMapsPlaces(apiKey: "AIzaSyDFE6FPAd-brYpZSAp0gdsJ8aT18BGiAnI");
  List<Map<String, dynamic>> allFacilities = [];
  int currentPage = 1;
  int facilitiesPerPage = 5;

  @override
  void initState() {
    super.initState();
    getFacilities(); // Fetch all facilities
  }

  Future<void> getFacilities() async {
    List<Geocoding.Location> userLocations =
    await Geocoding.locationFromAddress(widget.userLocation);

    if (userLocations.isNotEmpty) {
      Geocoding.Location userLocation = userLocations.first;

      String searchWord;
      if (widget.specialization == "Any")
        searchWord = "Hospital|Clinic|Klinik";
      else
        searchWord = widget.specialization;

      String? nextPageToken;

      do {
        PlacesSearchResponse response = await places.searchNearbyWithRankBy(
          Location(
            lat: userLocation.latitude!,
            lng: userLocation.longitude!,
          ),
          "distance",
          type: 'health',
          keyword: searchWord,
          pagetoken: nextPageToken,
        );

        if (response.isOkay) {
          for (PlacesSearchResult result in response.results) {
            String facilityName = result.name ?? 'N/A';

            double latitude = result.geometry!.location.lat;
            double longitude = result.geometry!.location.lng;
            double distance = await Geolocator.distanceBetween(
              userLocation.latitude!,
              userLocation.longitude!,
              latitude,
              longitude,
            );

            if (distance <= (widget.distancePreference * 1000)) {
              double formattedDistance = distance / 1000;

              allFacilities.add({
                'name': facilityName ?? 'N/A',
                'distance': formattedDistance.toStringAsFixed(2) + ' km',
              });
            }
          }
        } else {
          print('Error: ${response.errorMessage}');
        }

        // Retrieve the next page token from the response
        nextPageToken = response.nextPageToken;
      } while (nextPageToken != null);

      allFacilities.sort((a, b) {
        double distanceA =
        double.parse(a['distance'].replaceAll(RegExp(r'[^0-9\.]'), ''));
        double distanceB =
        double.parse(b['distance'].replaceAll(RegExp(r'[^0-9\.]'), ''));
        return distanceA.compareTo(distanceB);
      });

      // Call getFacilityData() after allFacilities is populated
      getFacilityData();
    }
  }

  void getFacilityData() {
    final int startIndex = (currentPage - 1) * facilitiesPerPage;
    final int endIndex = startIndex + facilitiesPerPage;
    facilityDataList = allFacilities.sublist(
      startIndex,
      endIndex.clamp(0, allFacilities.length),
    );

    setState(() {}); // Update the UI with the fetched data
  }

  void goToNextPage() {
    setState(() {
      currentPage++;
    });
    getFacilityData(); // Fetch the facilities for the next page
  }

  void goToPreviousPage() {
    setState(() {
      currentPage = (currentPage > 1) ? currentPage - 1 : 1;
    });
    getFacilityData(); // Fetch the facilities for the previous page
  }

  @override
  void dispose() {
    // Cancel ongoing requests to avoid calling setState() after disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Healthcare Facilities'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: goToPreviousPage,
                child: Text('Previous Page'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: goToNextPage,
                child: Text('Next Page'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: facilityDataList.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> facilityData = facilityDataList[index];

                return GestureDetector(
                  onTap: () {
                    // Remaining code...
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
          ),
        ],
      ),
    );
  }
}
