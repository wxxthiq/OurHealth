import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/Pharmacy/pharmacy_manage_patients.dart';
import 'package:ourhealth/Pharmacy/prescription_requests_page.dart';
import 'package:ourhealth/pages/filter_page.dart';
import 'package:ourhealth/service/authentication.dart';

import '../helper/helper_function.dart';
import '../service/database_service.dart';
import '../service/notification_service.dart';
import '../widgets/navigationbar.dart';
import '../widgets/pharmacy_navigationbar.dart';
import '../widgets/widgets.dart';


class pharmacyHomePage extends StatefulWidget {
  const pharmacyHomePage({Key? key}) : super(key: key);

  @override
  State<pharmacyHomePage> createState() => _PharmacyHomePageState();
}

class _PharmacyHomePageState extends State<pharmacyHomePage> {
  String userName = "";
  String email = "";
  String password = "";
  String profilePic = "";
  String userEmail = "";
  String pharmacyName = "";
  authentication auth = authentication();

  void initState() {
    super.initState();
    gettingUserData();
  }

  gettingUserData() async {
    WidgetsFlutterBinding.ensureInitialized();
    await HelperFunctions.getUserName().then((value) {
      setState(() {
        userName = value!;
        gettingPharmacyData(userName);
      });
    });
    await NotificationService.initializeNotifications(email,context);
  }

  Future<void> gettingPharmacyData(String fullName) async {
    CollectionReference pharmaciesCollection =
    FirebaseFirestore.instance.collection('pharmacists');
    QuerySnapshot<Object?> snapshot =
    await pharmaciesCollection.where('fullName', isEqualTo: fullName).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot<Object?> pharmacyDoc = snapshot.docs[0];
      setState(() {
        pharmacyName = pharmacyDoc['pharmacyName'];
        email = pharmacyDoc['email'];
        profilePic = pharmacyDoc['profilePic'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profilePic.isNotEmpty
                        ? NetworkImage(profilePic) as ImageProvider<Object>?
                        : AssetImage("assets/dp.jpeg"),
                  ),
                  SizedBox(width: 90),
                  Container(
                    width: 200, // Adjust the width as needed
                    child: Image.asset(
                        "assets/OurHealthLogo.png"),
                  ),
                ],
              ),
              SizedBox(height: 35),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Pharmacist " + userName,
                    style: TextStyle(
                      fontSize: 30,
                      color: Color(0xFF5D3FD3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    pharmacyName,
                    style: TextStyle(
                      fontSize: 30,
                      color: Color(0xFF5D3FD3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => prescriptionRequestsPage(
                        doctorEmail: email,
                        healthcareFacility: pharmacyName ,)),
                  );},
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.all(4),
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, size: 60, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Manage Refill Requests",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => pharmacyManagePatientsPage(
                      doctorEmail: email,)),
                  );},
               child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF5D3FD3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.all(4),
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.supervisor_account, size: 60, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Manage Customers",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
      bottomNavigationBar: pharmacistNavBar(email: email,),
    );
  }
}
