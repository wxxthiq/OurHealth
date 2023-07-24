import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/pages/pharmacy_filter_page.dart';
import 'package:ourhealth/service/authentication.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helper/helper_function.dart';
import '../service/notification_service.dart';
import '../widgets/navigationbar.dart';
import 'filter_page.dart';
import 'history_type_page.dart';
import 'medical_history_list_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{

  String userName = "";
  String email = "";
  String password = "";
  String profilePic = "";
  authentication auth = authentication();



  void initState(){
    super.initState();
    gettingUserData();


  }

  gettingUserData() async{
    WidgetsFlutterBinding.ensureInitialized();
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });


    await HelperFunctions.getUserEmail().then((value) {
      setState(() {
        email = value!;
      });
    });

    CollectionReference patientCollection =
    FirebaseFirestore.instance.collection('users');
    QuerySnapshot<Object?> snapshot =
    await patientCollection.where('email', isEqualTo: email).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot<Object?> patientDoc = snapshot.docs[0];
      setState(() {

        userName = patientDoc['fullName'];
        profilePic = patientDoc['profilePic'] ;

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
                    "Welcome,",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userName,
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
                    MaterialPageRoute(builder: (context) => FilterScreen(appointment: false)),
                  );
                },
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
                          Icon(Icons.search, size: 60, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Search for healthcare facilities",
                            style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Outfit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FilterScreen()),
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
                          Text("Book an appointment", style: TextStyle(fontSize: 18,color: Colors.white, fontFamily: 'Outfit',),),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PharmacyFilter()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.all(4),
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medication, size: 60, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Find medication",
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => historyTypePage(email: email),),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.all(4),
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, size: 60, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "View your medical history",
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
              SizedBox(height: 20),

            ],
          ),
        ),
      ),

      bottomNavigationBar: navBar(email: email,),
    );
  }
}

