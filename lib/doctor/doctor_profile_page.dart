import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helper/helper_function.dart';
import '../service/authentication.dart';
import '../widgets/widgets.dart';
import '../pages/login_page.dart';

class doctorProfilePage extends StatefulWidget {
  final String email;

  const doctorProfilePage({Key? key, required this.email}) : super(key: key);

  @override
  State<doctorProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<doctorProfilePage> {
  // Variables to hold profile information
  String? profilePic;

  String name = "";
  String dob = '';
  String phoneNumber = '';
  String gender = '';
  String healthcareFacility = '';
  String specialty = '';
  String languages = '';
  bool showSnackbar = true;
  authentication auth = authentication();

  // Controller for editing the phone number
  TextEditingController phoneController = TextEditingController();

  // Edit mode flag
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    // gettingUserData();
    gettingDoctorData(widget.email);
  }

  gettingUserData() async {
    String? pic = await HelperFunctions.getProfilePic();
    setState(() {
      profilePic = pic;
    });

    await HelperFunctions.getUserName().then((value) {
      setState(() {
        name = value!;
      });
    });
  }

  Future<void> gettingDoctorData(String email) async {
    CollectionReference doctorsCollection =
        FirebaseFirestore.instance.collection('doctors');
    QuerySnapshot<Object?> snapshot =
        await doctorsCollection.where('email', isEqualTo: email).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot<Object?> doctorDoc = snapshot.docs[0];
      setState(() {
        healthcareFacility = doctorDoc['healthcareFacility'];
        phoneNumber = doctorDoc['phoneNumber'];
        name = doctorDoc['fullName'];
        profilePic = doctorDoc['profilePic'];
        languages = doctorDoc['languages'];
        specialty = doctorDoc['specialty'];
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
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
      Reference reference = FirebaseStorage.instance
          .ref()
          .child("profilePictures/$name" + "_profilePic.jpg");

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

  Future<void> updateProfilePicInFirestore(String profilePicUrl) async {

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: widget.email)
        .get();

    // Update the profilePic field in the document
    querySnapshot.docs.forEach((doc) async {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doc.id)
          .update({'profilePic': profilePicUrl});
    });
  }

  Future<void> updatePhoneNumberInFirestore(String phoneNumber) async {
    // Get the reference to the document with the matching name
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: widget.email)
        .get();

    // Update the phoneNumber field in the document
    querySnapshot.docs.forEach((doc) async {
      if (phoneNumber.isNotEmpty) {
        await doc.reference.update({'phoneNumber': phoneNumber});
      }
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
                              ? NetworkImage(profilePic!)
                                  as ImageProvider<Object>?
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
                      "Dr."+name,
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
                      'Doctor at',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      healthcareFacility,
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
                      'Specialty',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      specialty,
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
                      'Languages',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D3FD3),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      languages,
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
                            onTap: () {
                              setState(() {
                                phoneController.text = phoneNumber;
                                phoneController.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset: phoneController.text.length));
                                String? validationResult =
                                    validatePhoneNumber(phoneController.text);
                                if (validationResult != null) {
                                  phoneController.clear();
                                  phoneController.text = validationResult;
                                }
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
              const SizedBox(height: 18.0),

              if (isEditMode)
                Center(
                  child: InkWell(
                    onTap: () {
                      String newPhoneNumber = phoneController.text;

                      // If the new phone number is blank, set it to the current phone number
                      if (newPhoneNumber.isEmpty) {
                        newPhoneNumber = phoneNumber;
                      }

                      // Validate phone number
                      String? validationResult =
                          validatePhoneNumber(newPhoneNumber);
                      if (validationResult == null) {
                        // Update the phone number in Firestore
                        updatePhoneNumberInFirestore(newPhoneNumber);

                        // Update the profile picture in Firebase Storage
                        if (profilePic != null) {
                          File imageFile = File(profilePic!);
                          uploadImageToFirebase(imageFile).then((downloadURL) {
                            if (downloadURL != null) {

                              // Update the profile picture in Firestore
                              FirebaseFirestore.instance
                                  .collection('doctors')
                                  .where('email', isEqualTo: widget.email)
                                  .get()
                                  .then((snapshot) {
                                if (snapshot.docs.length > 0) {
                                  snapshot.docs.forEach((doc) {
                                    doc.reference
                                        .update({'profilePic': downloadURL});
                                  });
                                }
                              });
                            }
                          });
                        }

                        setState(() {
                          isEditMode = false;
                          phoneNumber = newPhoneNumber;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 12.0),
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
                  backgroundColor:
                      MaterialStateProperty.all<Color>(const Color(0xFF5D3FD3)),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
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
