

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/doctor/appointment_requests_page.dart';
import 'package:ourhealth/service/authentication.dart';

import '../service/notification_service.dart';
import 'maange_patients_page.dart';
import '../helper/helper_function.dart';
import '../service/database_service.dart';
import '../widgets/doctor_navigationbar.dart';
import '../widgets/navigationbar.dart';
import '../widgets/widgets.dart';
import '../pages/filter_page.dart';
import '../pages/login_page.dart';


class doctorHomePage extends StatefulWidget {
  const doctorHomePage({Key? key}) : super(key: key);

  @override
  State<doctorHomePage> createState() => _doctorHomePageState();
}
class _doctorHomePageState extends State<doctorHomePage>{
  String userName = "";
  String email = "";
  String password = "";
  String profilePic = "";
  String userEmail = "";
  String healthcareFacility = "";
  authentication auth = authentication();

  void initState(){
    super.initState();
    gettingUserData();
    gettingUserData();
  }

  gettingUserData() async{

    await HelperFunctions.getUserName().then((value) {
      setState(() {
        userName = value!;
        gettingDoctorData(userName);
      });
    });

  }

  Future<void> gettingDoctorData(String fullName) async {
    CollectionReference doctorsCollection = FirebaseFirestore.instance.collection('doctors');
    QuerySnapshot<Object?> snapshot = await doctorsCollection.where('fullName', isEqualTo: fullName).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot<Object?> doctorDoc = snapshot.docs[0];
      setState(() {
        healthcareFacility = doctorDoc['healthcareFacility'];
        email = doctorDoc['email'];
        profilePic = doctorDoc['profilePic'];

      });
    }

    await NotificationService.initializeNotifications(email,context);
    // await NotificationService.startListeningNotificationEvents();
    // await NotificationService.foregroundHandler();
    // await NotificationService.backgroundHandler();

  }

  @override
  Widget build(BuildContext context){
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
                    "Dr."+userName,
                    style: TextStyle(
                      fontSize: 30,
                      color: Color(0xFF5D3FD3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    healthcareFacility,
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
                    MaterialPageRoute(builder: (context) => AppointmentRequestsPage(healthcareFacility: healthcareFacility, doctorEmail: email)),
                  );
                },
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
                        Icon(Icons.calendar_month,size: 60, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Manage Appointment Requests", style: TextStyle(fontSize: 18,color: Colors.white, fontFamily: 'Outfit',),),
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
                    MaterialPageRoute(builder: (context) => ManagePatientsPage(doctorEmail: email)),
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
                        Icon(Icons.person_pin_outlined,size: 60, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Manage Patients", style: TextStyle(fontSize: 18,color: Colors.white, fontFamily: 'Outfit',),),
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
      bottomNavigationBar: doctorNavBar(email: email),
    );
  }
}

