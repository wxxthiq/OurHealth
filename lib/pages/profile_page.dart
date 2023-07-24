import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helper/helper_function.dart';
import '../service/authentication.dart';
import '../widgets/widgets.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variables to hold profile information
  String? initialPhoneNumber;
  String? profilePic;
  String name = '';
  DateTime dob = DateTime.now();
  String phoneNumber = '';
  String gender = '';
  String? email = '';
  bool showSnackbar = true;
  authentication auth = authentication();

  // Controller for editing the phone number
  TextEditingController phoneController = TextEditingController();

  // Edit mode flag
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    gettingPatientData();

  }

  gettingPatientData() async {

    String? userEmail = await HelperFunctions.getUserEmail();
    setState(() {
      email = userEmail;
    });

    CollectionReference patientCollection =
    FirebaseFirestore.instance.collection('users');
    QuerySnapshot<Object?> snapshot =
    await patientCollection.where('email', isEqualTo: email).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot<Object?> patientDoc = snapshot.docs[0];
      setState(() {
        phoneNumber = patientDoc['phoneNumber'];
        initialPhoneNumber = phoneNumber;
        name = patientDoc['fullName'];
        profilePic = patientDoc['profilePic'] ;
        dob = (patientDoc['dob'] as Timestamp).toDate();
        gender = patientDoc['gender'];
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profilePic = pickedFile.path;
      });
    }
  }

  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      // Create a unique file name
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Create a reference to the file in Firebase Storage
      Reference reference = FirebaseStorage.instance.ref().child("profilePictures/$name" + "_profilePic.jpg");

      // Upload the file to Firebase Storage
      await reference.putFile(imageFile);

      // Get the download URL of the uploaded image
      String downloadURL = await reference.getDownloadURL();

      // Return the download URL
      return downloadURL;
    } catch (e) {
      print('Error uploading image to Firebase: $e');
      return null;
    }
  }


  Future<void> updatePhoneNumberInFirestore(String phoneNumber) async {
    // Get the reference to the document with the matching name
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    // Update the phoneNumber field in the document
    querySnapshot.docs.forEach((doc) async {
      await doc.reference.update({'phoneNumber': phoneNumber});
    });
  }

  String? validatePhoneNumber(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 8 || value.length > 11) {
        return 'Phone number must be 8-10 digits long';
      } else if (!value.contains(RegExp(r'^[0-9]+$'))) {
        return 'Phone number must contain only digits';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D3FD3),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                isEditMode = true;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    const SizedBox(height: 16.0),
                    CircleAvatar(
                      radius: 70.0,
                      backgroundColor: Colors.grey,
                      backgroundImage: profilePic != null
                          ? (profilePic!.startsWith('http')
                          ? NetworkImage(profilePic!) as ImageProvider<Object>?
                          : FileImage(File(profilePic!)))
                          : null,
                    ),
                    if (isEditMode)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D3FD3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      DateFormat('dd MMMM yyyy').format(dob),
                      style: const TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      gender,
                      style: const TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    isEditMode
                        ? TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: phoneNumber,
                      ),
                      enabled: isEditMode,
                      validator: validatePhoneNumber,
                      onTap: () {
                        setState(() {
                          if (!isEditMode) {
                            // Entering edit mode, set the initial phone number value
                            phoneController.text = phoneNumber;
                            phoneController.selection = TextSelection.fromPosition(
                              TextPosition(offset: phoneController.text.length),
                            );
                          }
                          //
                        });
                      },
                    )
                        : Text(
                      isEditMode ? phoneController.text : phoneNumber,
                      style: const TextStyle(fontSize: 20.0),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              const SizedBox(height: 16.0),
              const SizedBox(height: 16.0),
              if (isEditMode)
                Center(
                  child: InkWell(
                    onTap: () {
                      // Update the profile picture in Firebase Storage
                      if (profilePic != null) {
                        File imageFile = File(profilePic!);
                        uploadImageToFirebase(imageFile).then((downloadURL) {
                          if (downloadURL != null) {
                            // Save the download URL to shared preferences

                       //     HelperFunctions.saveProfilePicSF(downloadURL);

                            //Update the profile picture in Firestore
                            FirebaseFirestore.instance
                                .collection('users')
                                .where('email', isEqualTo: email)
                                .get()
                                .then((snapshot) {
                              if (snapshot.docs.length > 0) {
                                print(downloadURL);
                                snapshot.docs.forEach((doc) {
                                  doc.reference.update({'profilePic': downloadURL});
                                });
                              }
                            });
                          }
                        });
                      }

                      String? newPhoneNumber = phoneController.text;

                      // If the new phone number is blank, set it to the initial phone number text
                      if (newPhoneNumber.isEmpty) {
                        newPhoneNumber = initialPhoneNumber;
                      }

                      // Validate phone number
                      String? validationResult = validatePhoneNumber(newPhoneNumber);
                      if (validationResult == null && newPhoneNumber != '') {
                        // Check if the phone number has been edited
                        if (initialPhoneNumber != newPhoneNumber) {
                          // Save the updated phone number
                          setState(() {
                            phoneNumber = newPhoneNumber!;
                            // Update the phone number in Firestore
                            updatePhoneNumberInFirestore(phoneController.text);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Phone number saved'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }

                        setState(() {
                          isEditMode = false;
                          phoneNumber = newPhoneNumber!;
                        });
                      } else if (newPhoneNumber == '') {
                        // Show a message for blank phone number
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Phone number cannot be blank'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        // Show an error message for invalid phone number
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(validationResult!),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D3FD3),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                    ),
                  ),
                ),

              TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF5D3FD3)),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                ),
                onPressed: () {
                  auth.signOut();
                  nextScreenReplace(context, const LoginPage());
                },
                child: Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
