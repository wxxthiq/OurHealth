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

class hcfListPage extends StatefulWidget {
  final String userLocation;
  final double distancePreference;
  final String specialization;
  final String insuranceProvider;
  final String appointmentLocation;

  hcfListPage({
    required this.userLocation,
    required this.distancePreference,
    required this.specialization,
    required this.insuranceProvider,
    required this.appointmentLocation,
  });

  @override
  _HealthFacilitiesPageState createState() => _HealthFacilitiesPageState();
}

class _HealthFacilitiesPageState extends State<hcfListPage> {
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

      String searchWord;
      if (widget.specialization == "Any")
        searchWord = "Hospital|Clinic|Klinik";
      else
        searchWord = widget.specialization;

      String? nextPageToken;
      int resultsPerPage = 20; // Number of results to retrieve per page
      int maxResults = 100; // Maximum number of results to retrieve

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
            String facilityAddress = result.vicinity?.toString() ?? 'N/A';

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

              bool facilityExists = facilities.any((facility) => facility['name'] == facilityName);
              if (!facilityExists) {
                String contactNumber = 'N/A';
                String website = 'N/A';

                // Get the details of the place using the placeId
                PlacesDetailsResponse detailsResponse =
                await places.getDetailsByPlaceId(result.placeId ?? '');

                if (detailsResponse.isOkay) {
                  // Access the formatted phone number from the result
                  contactNumber = detailsResponse.result?.formattedPhoneNumber ?? 'N/A';
                  website = detailsResponse.result?.website ?? 'N/A';
                }

                String photoReference = result.photos != null &&
                    result.photos!.isNotEmpty &&
                    result.photos![0].photoReference != null
                    ? result.photos![0].photoReference!
                    : '';

                String photoUrl = photoReference.isNotEmpty ? await getPictureUrl(photoReference) : '';
                List<String> operationHours = result.openingHours?.weekdayText?.toList() ?? ['N/A'];
print(result.openingHours?.weekdayText);

                facilities.add({
                  'name': facilityName ?? 'N/A',
                  'address': facilityAddress ?? 'N/A',
                  'pictureUrl': photoUrl,
                  'latitude': latitude,
                  'longitude': longitude,
                  'operationHours': operationHours,
                  'contactNumber': contactNumber,
                  'website': website,
                  'distance': formattedDistance.toStringAsFixed(2) + ' km',
                });
              }
            }
          }
        } else {
          print('Error: ${response.errorMessage}');
        }

        // Retrieve the next page token from the response
        nextPageToken = response.nextPageToken;
        maxResults -= resultsPerPage; // Reduce the remaining results count

      } while (nextPageToken != null && maxResults > 0);

      facilities.sort((a, b) {
        double distanceA = double.parse(a['distance'].replaceAll(RegExp(r'[^0-9\.]'), ''));
        double distanceB = double.parse(b['distance'].replaceAll(RegExp(r'[^0-9\.]'), ''));
        return distanceA.compareTo(distanceB);
      });
    }

    return facilities;
  }

  Future<List<Map<String, dynamic>>> getExcelFacilities() async {
    String assetPath = " ";
    String assetPath2 = " ";
    int columnNumber = 1;
    List<String> hospitalNames = [];
    List<String> clinicNames = [];

    if (widget.insuranceProvider == "Etiqa Family Takaful") {
      assetPath = 'assets/ETIQA_HOSPITALS.xlsx';
      columnNumber = 1;
    } else if (widget.insuranceProvider == "Tokio Marine Life Preferred") {
      assetPath = 'assets/TM_CLINICS.xlsx';
      assetPath2 = 'assets/TM_HOSPITALS.xlsx';
      columnNumber = 1;
    } else if (widget.insuranceProvider == "MSIG") {
      assetPath = 'assets/MSIG.xlsx';
      columnNumber = 1;
    } else if (widget.insuranceProvider == "The Pacific Insurance Berhad") {
      assetPath = 'assets/PACIFIC.xlsx';
      columnNumber = 1;
    } else if (widget.insuranceProvider == "Hong Leon Assurance Berhad") {
      assetPath = 'assets/HONGLEON.xlsx';
      columnNumber = 2;
    } else {
      assetPath = 'assets/PACIFIC.xlsx';
    }

    // Read the Excel files
    var bytes = await rootBundle.load(assetPath);
    var excel = Excel.decodeBytes(bytes.buffer.asUint8List());

    // Get the "CLINIC NAME" column values from the first file
    var sheet = excel.tables['Listing'];
    if (sheet == null) {
      print('Sheet not found in first Excel file');
      return [];
    }

    if (widget.insuranceProvider == "Tokio Marine Life Preferred") {
      var bytes2 = await rootBundle.load(assetPath2);
      var excel2 = Excel.decodeBytes(bytes2.buffer.asUint8List());
      var sheet2 = excel2.tables['Listing'];

      if (sheet2 == null) {
        print('Sheet not found in second Excel file');
        return [];
      }

      for (var row in sheet2.rows) {
        if (row != null && row.isNotEmpty) {
          var cell = row[columnNumber];
          if (cell != null) {
            hospitalNames.add(cell?.value as String? ?? '');
          }
        }
      }
      hospitalNames.removeAt(0);
    }

    for (var row in sheet.rows) {
      if (row != null && row.isNotEmpty) {
        var cell = row[columnNumber];
        if (cell != null) {
          clinicNames.add(cell?.value as String? ?? ' ');
        }
      }
    }

    // Remove the header row
    clinicNames.removeAt(0);
    clinicNames.addAll(hospitalNames);

    List<Geocoding.Location> userLocations =
    await Geocoding.locationFromAddress(widget.userLocation);
    Geocoding.Location userLocation = userLocations.first;

    List<String> facilityNames = clinicNames;
    List<Map<String, dynamic>> placesList = [];

    // Batch size for each API request
    int batchSize = 50;

    // Divide the facility names into batches
    List<List<String>> batches = [];
    for (int i = 0; i < facilityNames.length; i += batchSize) {
      int end = i + batchSize;
      if (end > facilityNames.length) {
        end = facilityNames.length;
      }
      batches.add(facilityNames.sublist(i, end));
    }

    // Perform API requests for each batch
    try{
      await Future.forEach(batches, (List<String> batch) async {
        // Prepare a list of futures for autocomplete predictions
        List<Future<PlacesAutocompleteResponse>> predictionFutures = [];

        batch.forEach((facilityName) {
          predictionFutures.add(places.autocomplete(
            facilityName,
            location: Location(
              lat: userLocation.latitude!,
              lng: userLocation.longitude!,
            ),
          ));
        });

        // Wait for all autocomplete predictions to complete
        List<PlacesAutocompleteResponse> predictionResponses =
        await Future.wait(predictionFutures);

        // Process the autocomplete predictions
        for (PlacesAutocompleteResponse predictionResponse in predictionResponses) {
          if (predictionResponse.isOkay && predictionResponse.predictions.isNotEmpty) {
            Prediction prediction = predictionResponse.predictions.first;
            PlacesDetailsResponse detailsResponse =
            await places.getDetailsByPlaceId(prediction.placeId!);
            if (detailsResponse.isOkay) {
              PlaceDetails result = detailsResponse.result!;
              String facilityName = result.name ?? '';
              print(facilityName);
              if (facilityName.isNotEmpty) {
                String facilityAddress = result.formattedAddress ?? 'N/A';
                double latitude = result.geometry!.location.lat;
                double longitude = result.geometry!.location.lng;
                double distance = await Geolocator.distanceBetween(
                  userLocation.latitude!,
                  userLocation.longitude!,
                  latitude,
                  longitude,
                );

                if (distance <= (widget.distancePreference * 1000)) {
                  String contactNumber = result.formattedPhoneNumber ?? 'N/A';
                  String website = result.website ?? 'N/A';

                  String photoReference =
                  result.photos != null &&
                      result.photos!.isNotEmpty &&
                      result.photos![0].photoReference != null
                      ? result.photos![0].photoReference!
                      : '';

                  String photoUrl = await getPictureUrl(photoReference);
                  List<String> operationHours = result.openingHours?.weekdayText?.toList() ?? ['N/A'];
                  double formattedDistance = distance / 1000;
                  print("check");
                  print(facilityName);
                  print(formattedDistance.toStringAsFixed(2) + ' km');
                  print(operationHours);
                  print(contactNumber);
                  print(photoUrl);
                  placesList.add({
                    'name': facilityName ?? 'N/A',
                    'distance': formattedDistance.toStringAsFixed(2) + ' km' ?? "N/A",
                    'address': facilityAddress ?? 'N/A',
                    'latitude': latitude,
                    'longitude': longitude,
                    'operationHours': operationHours ?? " ",
                    'contactNumber': contactNumber ?? 'N/A',
                    'website': website ?? 'N/A',
                    'pictureUrl': photoUrl ?? ' ',
                  });
                }
              }
            }

          }
        }
      });
    } catch( e){
      print('Error: $e');

    }

    placesList.sort((a, b) {
      double distanceA = double.parse(a['distance'].replaceAll(RegExp(r'[^0-9\.]'), ''));
      double distanceB = double.parse(b['distance'].replaceAll(RegExp(r'[^0-9\.]'), ''));
      return distanceA.compareTo(distanceB);
    });

    return placesList;
  }


  Future<List<Map<String, dynamic>>> getFacilityData() {
    if (widget.insuranceProvider == "Any") {
      return getFacilities();
    } else {
      return getExcelFacilities();
    }
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
        future: getFacilityData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                    'Fetching facilities...',
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
                            patientLocation: widget.userLocation ?? 'N/A',
                            appointmentLocation: widget.appointmentLocation ?? 'N/A',
                            pharmacySearch: false,
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
