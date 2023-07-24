import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/helper/helper_function.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../service/authentication.dart';
import '../widgets/widgets.dart';
import 'dart:io';
import 'home_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>{
  bool _isLoading = false;
  String? _imageUrl;
  File? _image;
  final formKey = GlobalKey<FormState>();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  String emailOrUsername = "";
  String password = "";
  String fullName = "";
  String dateOfBirth = "";
  DateTime dob= DateTime.now();
  String? gender;
  String phoneNumber = "";

  authentication auth = authentication();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF5D3FD3),
        ),
        body: _isLoading? Center(child:CircularProgressIndicator(color: Theme.of(context).primaryColor)) :
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
            child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget> [
                    const Text("Patient Registration",
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 50),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null ? const Icon(Icons.person, size: 40) : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Your profile picture ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
                    const SizedBox(height: 50),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                        labelText: "Your Fullname",
                        prefixIcon: Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor
                        ),
                      ),
                      onChanged: (val){
                        setState((){
                          fullName = val;
                        });
                      },
                      //Email validation
                      validator: (val) {
                        if (val!.isNotEmpty){
                          return null;
                          }
                        else{
                          return "Please insert your full name";
                        }
                      },
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                        labelText: "Your Date of Birth",
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      controller: _dateController,
                      onTap: () async {
                        // Show a date picker and update the selected date
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Color(0xFF5D3FD3),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            dob = pickedDate;
                            _dateController.text = DateFormat('dd-MM-yyyy').format(dob);
                            String formattedDob = DateFormat('dd-MM-yyyy').format(pickedDate!);
                            _dateController.text = formattedDob;
                            print(_dateController.text);


                          });
                        }
                      },
                      validator: (val) {
                        if (val!.isEmpty) {
                          return "Please select a date of birth";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height : 15),
                    DropdownButtonFormField<String>(
                      decoration: textInputDecoration.copyWith(
                        labelText: "Your Gender",
                        prefixIcon: Icon(
                          Icons.people,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      value: gender,
                      onChanged: (val) {
                        setState(() {
                          gender = val;
                        });
                      },
                      items: [
                        DropdownMenuItem(
                          value: "Male",
                          child: Text("Male"),
                        ),
                        DropdownMenuItem(
                          value: "Female",
                          child: Text("Female"),
                        ),
                      ],
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Please select your gender";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height : 15),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                        labelText: "Your Phone Number",
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (val) {
                        setState(() {
                          phoneNumber = val;
                        });
                      },
                      validator: (val) {
                        if (val!.isEmpty) {
                          return "Please enter your phone number";
                        }
                        return null;
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
                          "Register",
                          style: TextStyle(color: Colors.white, fontSize:16),
                        ),
                        onPressed: () {
                          register();
                        },
                      ),
                    ),
                    const SizedBox(height : 10),
                    Text.rich(
                        TextSpan(
                            text: "Already have an account?",
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            children: <TextSpan>[
                              TextSpan(
                                  text: "Login here",
                                  style: const TextStyle(color: Colors.black, decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()..onTap = (){
                                    nextScreen(context, const LoginPage());
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
  register() async{
    if(formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Capitalize the first letter of every word in the full name
      String capitalizedFullName = fullName.toLowerCase().split(' ').map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1);
        }
        return '';
      }).join(' ');

      if (_imageUrl != null) {
        await auth.registerUserWithEmailandPassword(
            capitalizedFullName, emailOrUsername, password, _imageUrl!, gender!, dob ,phoneNumber).then((value) async{
          if (value == true) {
            //save the shared pref state
            await HelperFunctions.saveUserLoggedInStatus(true);
            await HelperFunctions.saveUserEmailSF(emailOrUsername);
            await HelperFunctions.saveUserNameSF(fullName);
            await HelperFunctions.saveProfilePicSF(_imageUrl!);
            await HelperFunctions.saveDOBSF(dob);
            await HelperFunctions.saveGenderSF(gender!);
            await HelperFunctions.savephoneNumberSF(phoneNumber);
            nextScreenReplace(context, const HomePage());
          } else {
            setState(() {
              showSnackbar(context, Colors.red, "Please select a profile picture");
              _isLoading = false;
            });
          }
        });
      }

    }
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      setState(() {
        _isLoading = true; // Move this line inside setState
      });

      Reference ref = FirebaseStorage.instance.ref().child("profilePictures/$fullName" + "_profilePic.jpg");
      await ref.putFile(File(_image!.path));
      String imageUrl = await ref.getDownloadURL();

      setState(() {
        _imageUrl = imageUrl;
        _isLoading = false; // Move this line inside setState
      });
    }
  }
}


