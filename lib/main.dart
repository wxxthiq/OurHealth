import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/pages/login_page.dart';

import 'helper/helper_function.dart';
import 'pages/home_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}): super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  bool _isSignedIn = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserLoggedInStatus();
  }

  getUserLoggedInStatus() async{
    await HelperFunctions.getUserLoggedInStatus().then((value){
    if (value!=null){
      setState((){
        _isSignedIn = value;
      });
    }
      });
    }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    theme: ThemeData(
      primaryColor: Color(0xFF5D3FD3),
      scaffoldBackgroundColor: Colors.white
    ),
    debugShowCheckedModeBanner: false,
    home: _isSignedIn ? const HomePage() : const LoginPage() ,

    );
  }
}
