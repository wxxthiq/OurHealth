import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ourhealth/pages/healthcare_facilities_page.dart';
import 'package:ourhealth/pages/pharmacy_list_page.dart';
import 'package:ourhealth/service/location_auto_complete_response.dart';


import '../service/autocomplete_prediction.dart';
import '../service/network_utility.dart';
import '../widgets/widgets.dart';
import 'hcf_list_page.dart';
class PharmacyFilter extends StatefulWidget {
  final bool appointment; // Flag to indicate whether to show the appointment radio buttons or not

  PharmacyFilter({this.appointment = true});
  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<PharmacyFilter> {

  Future<void> _getUserLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("disabled");
      // Location services are disabled, handle this case
      return;
    }

    // Request permission to access location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print("disabled");
      // Location permissions are permanently denied, handle this case
      return;
    }

    if (permission == LocationPermission.denied) {
      // Location permissions are denied, ask for permission
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // Location permissions are denied, handle this case
        return;
      }
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Reverse geocoding to get the address from coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);

    // Use the addresses list to access the address information
    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks.first;

      String thoroughfare = placemark.thoroughfare ?? '';
      String subThoroughfare = placemark.subThoroughfare ?? '';
      String locality = placemark.locality ?? '';
      String administrativeArea = placemark.administrativeArea ?? '';
      String postalCode = placemark.postalCode ?? '';
      String name = placemark.name ?? '';

      String fullAddress = '$name, $subThoroughfare $thoroughfare, $postalCode, $locality, $administrativeArea';

      // Use the fullAddress variable as needed
      print(fullAddress);

      // Use the fullAddress variable as needed
      setState(() {
        _addressController.text = fullAddress;
      });

    }
  }

  void placeAutocomplete(String query) async{
    Uri uri = Uri.https("maps.googleapis.com", 'maps/api/place/autocomplete/json',{
      "input": query,
      "key": "AIzaSyDFE6FPAd-brYpZSAp0gdsJ8aT18BGiAnI",
    });

    //Making the get request
    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null){
      locationAutocompleteResponse result = locationAutocompleteResponse.parseAutocompleteResult(response);
      if (result.predictions != null){
        setState(() {
          locationPredictions = result.predictions!;
        });
      }
      print(response);
    }
  }

  List<AutocompletePrediction> locationPredictions = [];
  AutocompletePrediction? _selectedPrediction;
  TextEditingController _addressController = TextEditingController();
  double _distancePreference = 3.0; // Default distance preference in km
  String _selectedAppointmentLocation = "";
  bool _isListViewVisible = false;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Filter'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //SizedBox(height: 10.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      decoration: textInputDecoration.copyWith(
                        labelText: "Enter your location",
                        prefixIcon: Icon(
                            Icons.add_location_alt,
                            color: Theme.of(context).primaryColor
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedPrediction = null;
                          _isListViewVisible = true;
                        });
                        // Handle the address input
                        placeAutocomplete(value);
                      },
                    ),
                  ),

                  SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      // Handle the GPS icon pressed
                      // This function will be called when the GPS icon is tapped
                      _getUserLocation();
                      _isListViewVisible = false;
                    },
                    child: Icon(Icons.gps_fixed, color: Color(0xFF5D3FD3)),
                  ),
                ],
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    if (_isListViewVisible)
                      Column(
                        children: locationPredictions.map((prediction) {
                          return ListTile(
                            title: Text(prediction.description!),
                            onTap: () {
                              setState(() {
                                _selectedPrediction = prediction;
                                _addressController.text = prediction.description!;
                                _isListViewVisible = false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 25.0),
              Text(
                'Distance Preference: ${_distancePreference.toStringAsFixed(1)} km',
                style: TextStyle(fontSize: 18.0, color: Color(0xFF5D3FD3)),
              ),
              Slider(
                activeColor: Theme.of(context).primaryColor,
                value: _distancePreference,
                min: 1.0,
                max: 29.0,
                divisions: 30,
                onChanged: (value) {
                  setState(() {
                    _distancePreference = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  child: const Text(
                    "Begin search",
                    style: TextStyle(color: Colors.white, fontSize:16),
                  ),
                  onPressed: _addressController.text.isEmpty
                      ? null :
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => pharmacyListPage(
                            userLocation: _addressController.text,
                            distancePreference: _distancePreference,
                            appointmentLocation: _selectedAppointmentLocation ),
                      ),);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

