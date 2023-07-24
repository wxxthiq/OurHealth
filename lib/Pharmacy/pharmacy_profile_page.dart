import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helper/helper_function.dart';
import '../pages/login_page.dart';
import '../service/authentication.dart';
import '../widgets/widgets.dart';

import 'package:intl/intl.dart';

class pharmacistProfilePage extends StatefulWidget {
  final String email;
  const pharmacistProfilePage({Key? key,required this.email}) : super(key: key);

  @override
  State<pharmacistProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<pharmacistProfilePage> {
  // Variables to hold profile information
  String? profilePic;
  String name = '';
  String pharmacyName = '';


  bool showSnackbar = true;
  authentication auth = authentication();

  // Controller for editing the phone number
  TextEditingController phoneController = TextEditingController();

  // Edit mode flag
  bool isEditMode = false;

  @override
  void initState() {
    print(widget.email);
    super.initState();
    gettingPharmacistData();
  }

  gettingPharmacistData() async {


    CollectionReference patientCollection =
    FirebaseFirestore.instance.collection('pharmacists');
    QuerySnapshot<Object?> snapshot =
    await patientCollection.where('email', isEqualTo: widget.email).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot<Object?> patientDoc = snapshot.docs[0];
      setState(() {
        name = patientDoc['fullName'];
        profilePic = patientDoc['profilePic'] ;
        pharmacyName = patientDoc['pharmacyName'];
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
                      'Pharmacy Name',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      pharmacyName,
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
                      'Email',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      widget.email,
                      style: const TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              const SizedBox(height: 16.0),
              if (isEditMode)
                Center(
                  child: InkWell(
                    onTap: () {
                      // Update the profile picture in Firebase Storage
                      if (profilePic != null) {
                       // print(profilePic);
                        print("Email is");
                        print(widget.email);
                        File imageFile = File(profilePic!);
                        uploadImageToFirebase(imageFile).then((downloadURL) {
                          if (downloadURL != null) {
                            FirebaseFirestore.instance
                                .collection('pharmacists')
                                .where('email', isEqualTo: widget.email)
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
