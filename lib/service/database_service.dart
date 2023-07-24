import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Reference for collections
  final CollectionReference userCollection =
  FirebaseFirestore.instance.collection("users");

  // Reference for doctor collections
  final CollectionReference doctorCollection =
  FirebaseFirestore.instance.collection("doctors");

  // Saving the users data
  Future savingUserData(String fullName, String email, String profilePic,
      String gender, String phoneNumber, DateTime dob) async {
    if (uid != null) {
      // Check if the user is a doctor
      DocumentSnapshot doctorSnapshot =
      await doctorCollection.doc(uid).get();
      if (doctorSnapshot.exists) {
        // User is a doctor, save data in doctor collection
        return await doctorCollection.doc(uid).set({
          "fullName": fullName,
          "email": email,
          "profilePic": profilePic,
          "gender": gender,
          "phoneNumber": phoneNumber,
          "dob": dob,
          "uid": uid,
        });
      } else {
        // User is not a doctor, save data in user collection
        return await userCollection.doc(uid).set({
          "fullName": fullName,
          "email": email,
          "profilePic": profilePic,
          "gender": gender,
          "phoneNumber": phoneNumber,
          "dob": dob,
          "uid": uid,
        });
      }
    }
  }

  Future gettingUserData(String email) async {
    QuerySnapshot userSnapshot =
    await userCollection.where("email", isEqualTo: email).get();
    QuerySnapshot doctorSnapshot =
    await doctorCollection.where("email", isEqualTo: email).get();

    if (userSnapshot.docs.isNotEmpty) {
      // User exists in user collection
      return userSnapshot;
    } else if (doctorSnapshot.docs.isNotEmpty) {
      // User exists in doctor collection
      return doctorSnapshot;
    } else {
      // User not found
      return null;
    }
  }
}
