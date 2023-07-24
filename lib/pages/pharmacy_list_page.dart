import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_excel/excel.dart';
import 'package:geocoding/geocoding.dart' as Geocoding;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'healthcare_facility_details_page.dart';
import 'package:google_maps_webservice/places.dart';

class pharmacyListPage extends StatefulWidget {
  final String userLocation;
  final double distancePreference;
  final String appointmentLocation;

  pharmacyListPage({
    required this.userLocation,
    required this.distancePreference,
    required this.appointmentLocation,
  });

  @override
  _HealthFacilitiesPageState createState() => _HealthFacilitiesPageState();
}

class _HealthFacilitiesPageState extends State<pharmacyListPage> {
  List<Map<String, dynamic>> facilityDataList = [];

  final places = GoogleMapsPlaces(apiKey: "AIzaSyDFE6FPAd-brYpZSAp0gdsJ8aT18BGiAnI");

  @override
  void initState() {
    super.initState();
  }

  Future<String> getPictureUrl(String photoReference) async {
    if (photoReference.isNotEmpty) {
      final apiKey = 'AIzaSyDFE6FPAd-brYpZSAp0gdsJ8aT18BGiAnI';
      final url = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.request!.url.toString();
      }
    }

    return 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Image_not_available.png/640px-Image_not_available.png'; // Return a default image URL if photo URL retrieval fails
  }

  Future<List<Map<String, dynamic>>> getFacilities() async {
    List<Map<String, dynamic>> facilities = [];

    List<Geocoding.Location> userLocations =
    await Geocoding.locationFromAddress(widget.userLocation);

    if (userLocations.isNotEmpty) {
      Geocoding.Location userLocation = userLocations.first;
      PlacesSearchResponse response;
      String? nextPageToken;

      // Pagination parameters
      int resultsPerPage = 500; // Number of results to retrieve per page
      int maxResults = 1000; // Maximum number of results to retrieve

      do {
        List<Future<PlacesSearchResponse>> futures = [];

        for (int page = 0; page < maxResults ~/ resultsPerPage; page++) {
          futures.add(places.searchNearbyWithRankBy(
            Location(
              lat: userLocation.latitude!,
              lng: userLocation.longitude!,
            ),
            "distance",
            type: 'health',
            keyword: 'pharmacy | drug store',
            pagetoken: nextPageToken,

          ));
        }

        List<PlacesSearchResponse> responses = await Future.wait(futures);

        for (PlacesSearchResponse response in responses) {
          if (response.isOkay) {
            for (PlacesSearchResult result in response.results) {
              String facilityName = result.name ?? 'N/A';
              String facilityAddress = result.vicinity ?? 'N/A';

              double latitude = result.geometry!.location.lat;
              double longitude = result.geometry!.location.lng;
              double distance = await Geolocator.distanceBetween(
                userLocation.latitude!,
                userLocation.longitude!,
                latitude,
                longitude,
              );

              if (distance <= (widget.distancePreference * 1000)) {
                print(facilityName);
                double formattedDistance = distance/1000;

                bool facilityExists = facilities.any((facility) => facility['name'] == facilityName);
                if (!facilityExists){
                  String contactNumber = 'N/A';
                  String website =  'N/A';
                  // Get the details of the place using the placeId
                  PlacesDetailsResponse detailsResponse = await places.getDetailsByPlaceId(result.placeId ?? '');
                  if (detailsResponse.isOkay) {
                    // Access the formatted phone number from the result
                    contactNumber = detailsResponse.result?.formattedPhoneNumber ?? 'N/A';
                    website = detailsResponse.result?.website ?? 'N/A';
                  }


                  String photoReference = result.photos != null && result.photos!.isNotEmpty && result.photos![0].photoReference != null
                      ? result.photos![0].photoReference!
                      : '';
                  String photoUrl = await getPictureUrl(photoReference);

                  List<String> operationHours = detailsResponse.result?.openingHours?.weekdayText ?? ['N/A'];
                  facilities.add({
                    'name': facilityName ?? 'N/A',
                    'address': facilityAddress ?? 'N/A',
                    'pictureUrl': photoUrl,
                    'latitude': latitude,
                    'longitude': longitude,
                    'operationHours': operationHours ?? 'N/A',
                    'contactNumber': contactNumber ?? 'N/A',
                    'website': website ?? 'N/A',
                    'distance': formattedDistance.toStringAsFixed(2)+ ' km',
                  });
                }
              }
            }
          }
        }

        // Retrieve the next page token from the last response
        response = responses.last;
        nextPageToken = response.nextPageToken;

      } while (nextPageToken != null);

      facilities.sort((a, b) {
        double distanceA = double.parse(a['distance'].replaceAll(RegExp(r'[^0-9\.]'), ''));
        double distanceB = double.parse(b['distance'].replaceAll(RegExp(r'[^0-9\.]'), ''));
        return distanceA.compareTo(distanceB);
      });
    }

    return facilities;
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getFacilities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                    'Fetching pharmacies and drugstores...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            List<Map<String, dynamic>> facilityDataList = snapshot.data!;
            if (facilityDataList.isEmpty) {
              return Center(
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
              );
            } else {
              return ListView.builder(
                itemCount: facilityDataList.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> facilityData = facilityDataList[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FacilityDetailsPage(
                            facilityName: facilityData['name'] ?? 'N/A',
                            facilityPicture: facilityData['pictureUrl'] ?? 'N/A',
                            operationHours: facilityData['operationHours'] ?? ['N/A'],
                            facilityAddress: facilityData['address'] ?? 'N/A',
                            contactNumber: facilityData['contactNumber'] ?? 'N/A',
                            website: facilityData['website'] ?? 'N/A',
                            patientLocation: widget.userLocation,
                            appointmentLocation: widget.appointmentLocation,
                            pharmacySearch: true,
                          ),
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
              );
            }
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
