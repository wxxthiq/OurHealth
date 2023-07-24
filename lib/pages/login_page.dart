import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/Pharmacy/pharmacy_home_page.dart';
import 'package:ourhealth/pages/register_page.dart';
import 'package:ourhealth/service/authentication.dart';
import 'package:ourhealth/widgets/widgets.dart';

import '../helper/helper_function.dart';
import '../service/database_service.dart';
import '../doctor/doctor_home_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey =GlobalKey<FormState>();
  String emailOrUsername = "";
  String password = "";
  bool _isLoading = false;
  authentication auth = authentication();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Color(0xFF5D3FD3),
      // ),
      body: _isLoading ? Center( child: CircularProgressIndicator(color: Theme.of(context).primaryColor),) : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget> [
                const SizedBox(height: 100),
                Image.asset("assets/OurHealthLogo.png"),
                const SizedBox(height: 100),
                TextFormField(
                  decoration: textInputDecoration.copyWith(
                    labelText: "Your Email",
                    prefixIcon: Icon(
                      Icons.email,
                      color: Theme.of(context).primaryColor
                    ),
                  ),
                  onChanged: (val){
                    setState((){
                      emailOrUsername = val;
                    });
                  },
                  //Email validation
                  validator: (val) {
                    return RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(val!)
                        ? null
                        : "Please enter a valid email";
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  obscureText: true,
                  decoration: textInputDecoration.copyWith(
                    labelText: "Your Password",
                    prefixIcon: Icon(
                        Icons.lock,
                        color: Theme.of(context).primaryColor
                    ),
                  ),
                  onChanged: (val){
                    setState((){
                      password = val;
                    });
                  },
                  validator: (val) {
                    if (val!.length < 8) {
                      return "Password cannot be less than 8 characters";
                    } else {
                      return null;
                    }
                  },
                ),
                SizedBox(height : 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.white, fontSize:16),
                      ),
                      onPressed: () {
                        login();
                      },
                    ),
                  ),
                  const SizedBox(height : 10),
                  Text.rich(
                    TextSpan(
                      text: "Don't have an account?  ",
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Register here",
                          style: const TextStyle(color: Colors.black, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = (){
                            nextScreen(context, const RegisterPage());
                          }
                        ),
                      ]
                    )
                  ),
              ],
            )
          ),
        ),
      )
    );
  }
  login() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await auth.loginWithUserNameandPassword(emailOrUsername, password).then((value) async {
        if (value == true) {
          // Check if the user exists in the "users" collection
          QuerySnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: emailOrUsername)
              .get();

          // Check if the user exists in the "doctors" collection
          QuerySnapshot doctorSnapshot = await FirebaseFirestore.instance
              .collection('doctors')
              .where('email', isEqualTo: emailOrUsername)
              .get();

          QuerySnapshot pharmacistSnapshot = await FirebaseFirestore.instance
              .collection('pharmacists')
              .where('email', isEqualTo: emailOrUsername)
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            DocumentSnapshot userDoc = userSnapshot.docs[0];

            await HelperFunctions.saveUserLoggedInStatus(true);
            await HelperFunctions.saveUserEmailSF(emailOrUsername);
            await HelperFunctions.saveUserNameSF(userDoc['fullName']);
            await HelperFunctions.saveProfilePicSF(userDoc['profilePic']);

            nextScreenReplace(context, const HomePage());
          } else if (doctorSnapshot.docs.isNotEmpty) {
            // User is a doctor
             DocumentSnapshot doctorDoc = doctorSnapshot.docs[0];
            // await HelperFunctions.saveUserNameSF(doctorDoc['fullName']);
            // await HelperFunctions.saveUserLoggedInStatus(true);
            await HelperFunctions.saveUserNameSF(doctorDoc['fullName']);
            nextScreenReplace(context, const doctorHomePage());
            // Redirect to the doctor's page
            // Replace the nextScreenReplace() method with the appropriate navigation logic for the doctor's page
            // Example: nextScreenReplace(context, DoctorPage(doctorDoc));

          } else if (pharmacistSnapshot.docs.isNotEmpty){
            DocumentSnapshot pharmacistDoc = pharmacistSnapshot.docs[0];
            await HelperFunctions.saveUserNameSF(pharmacistDoc['fullName']);
            nextScreenReplace(context, const pharmacyHomePage());
          } else {
            // User not found in either collection
            showSnackbar(context, Colors.red, 'Invalid user');
          }
        } else {
          setState(() {
            showSnackbar(context, Colors.red, value);
            _isLoading = false;
          });
        }
      });
    }
  }

}
