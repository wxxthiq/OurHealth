import 'package:firebase_auth/firebase_auth.dart';
import 'package:ourhealth/helper/helper_function.dart';

import 'database_service.dart';

class authentication{
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  //login
  Future loginWithUserNameandPassword(String email, String password) async{

    try{
      User user = (await firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password : password
      )).user!;

      if (user != null){
        return true;
      }

    } on FirebaseAuthException catch(e){
      return e.message;
    }
  }
  //register
  Future registerUserWithEmailandPassword(String fullName, String email, String password, String profilePic, String gender, DateTime dob, String phoneNumber) async{

    try{
      User user = (await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password : password
        )).user!;

      if (user != null){
        //call the database to make the update
        await DatabaseService(uid: user.uid).savingUserData(fullName, email, profilePic, gender,phoneNumber, dob);
        return true;
      }


    } on FirebaseAuthException catch(e){
      return e.message;
    }
  }

  //sign out
  Future signOut() async{
    try{
      await HelperFunctions.saveUserLoggedInStatus(false);
      await HelperFunctions.saveUserEmailSF("");
      await HelperFunctions.saveUserNameSF("");
      await firebaseAuth.signOut();
    } catch (e) {
      return null;
    }
  }
}