import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ourhealth/pages/healthcare_facilities_page.dart';
import 'package:ourhealth/service/location_auto_complete_response.dart';


import '../service/autocomplete_prediction.dart';
import '../service/network_utility.dart';
import '../widgets/widgets.dart';
import 'facility_list_page.dart';
import 'hcf_list_page.dart';
class FilterScreen extends StatefulWidget {
  final bool appointment; // Flag to indicate whether to show the appointment radio buttons or not

  FilterScreen({this.appointment = true});
  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {

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

      String fullAddress = ' $name, $subThoroughfare $thoroughfare, $postalCode, $locality, $administrativeArea';

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
  String _selectedSpecialization = 'Any';
  String _selectedInsuranceProvider = 'Any';
  String appointmentLocation = "";
  String _selectedAppointmentLocation = "";
  bool _isListViewVisible = false;
  bool isAppointmentLocationSelected = false;

  // Define the list of available specializations and insurance providers
  List<String> _specializations = ['Any','General Care', 'Cardiology', 'Dermatology', 'Orthopedics', 'Pediatrics', 'Gastroenterology', 'Ophthalmology', 'Neurology', 'Obstetrics and Gynecology', 'Dentistry',];
  List<String> _insuranceProviders = ['Any', 'MSIG', 'Etiqa Family Takaful', 'Hong Leon Assurance Berhad','Tokio Marine Life Preferred','The Pacific Insurance Berhad'];

  @override
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
                max: 20.0,
                divisions: 19,
                onChanged: (value) {
                  setState(() {
                    _distancePreference = value;
                  });
                },
              ),
              if (widget.appointment)
                if (widget.appointment)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.0),
                      Text(
                        'Appointment Location',
                        style: TextStyle(fontSize: 18.0, color: Color(0xFF5D3FD3)),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: Colors.grey,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Radio(
                                  value: "My Location",
                                  groupValue: _selectedAppointmentLocation,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAppointmentLocation = value.toString();
                                      isAppointmentLocationSelected = true;
                                    });
                                  },
                                  activeColor: Color(0xFF5D3FD3),
                                ),
                                SizedBox(height: 80),
                                Text("My Location"),
                              ],
                            ),
                            Row(
                              children: [
                                Radio(
                                  value: "Healthcare Facility",
                                  groupValue: _selectedAppointmentLocation,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAppointmentLocation = value.toString();
                                      isAppointmentLocationSelected = true;
                                    });
                                  },
                                  activeColor: Color(0xFF5D3FD3),
                                ),
                                Text("Clinic / Hospital"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

              SizedBox(height: 16.0),
              Text(
                'Hospital/Clinic Specialization',
                style: TextStyle(fontSize: 18.0, color: Color(0xFF5D3FD3)),
              ),
              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                items: _specializations.map((String specialization) {
                  return DropdownMenuItem<String>(
                    value: specialization,
                    child: Text(specialization),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedSpecialization = value!;
                  });
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'Insurance Provider',
                style: TextStyle(fontSize: 18.0, color: Color(0xFF5D3FD3)),
              ),
              DropdownButtonFormField<String>(
                value: _selectedInsuranceProvider,
                items: _insuranceProviders.map((String provider) {
                  return DropdownMenuItem<String>(
                    value: provider,
                    child: Text(provider),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedInsuranceProvider = value!;
                  });
                },
              ),
              SizedBox(height: 25.0),
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
                  onPressed: _addressController.text.isEmpty || (widget.appointment && !isAppointmentLocationSelected)
                      ? null :
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => hcfListPage(
                            userLocation: _addressController.text,
                            distancePreference: _distancePreference,
                            specialization: _selectedSpecialization,
                            insuranceProvider: _selectedInsuranceProvider,
                            appointmentLocation: _selectedAppointmentLocation ),
                      ),
                    );
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

