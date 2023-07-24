import 'package:shared_preferences/shared_preferences.dart';

class HelperFunctions {

  //keys
  static String userLoggedInKey = "LOGGEDINKEY";
  static String userNameKey = "USERNAMEKEY";
  static String userEmailKey = "USEREMAILKEY";
  static String profilePicKey= "PROFILEPICKEY";
  static String genderKey= "GENDERKEY";
  static String dobKey= "DOBKEY";
  static String phoneNumberKey= "PHONENUMBERKEY";

  //saving the data to SF

  static Future<bool> saveUserLoggedInStatus (bool isUserLoggedIn) async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(userLoggedInKey, isUserLoggedIn);
  }

  static Future<bool> saveUserNameSF (String userName) async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userNameKey, userName);
  }

  static Future<bool> saveUserEmailSF (String userEmail) async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userEmailKey, userEmail);
  }

  static Future<bool> saveProfilePicSF (String profilePic) async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(profilePicKey, profilePic);
  }

  static Future<bool> saveDOBSF (DateTime dob) async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(dobKey, dob.toIso8601String());
  }

  static Future<bool> saveGenderSF (String gender) async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(genderKey, gender);
  }

  static Future<bool> savephoneNumberSF (String phoneNumber) async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(phoneNumberKey, phoneNumber);
  }
  //getting data from SF
  static Future<bool?> getUserLoggedInStatus() async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(userLoggedInKey);
  }

  static Future<String?> getProfilePic() async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(profilePicKey);
  }
  static Future<String?> getUserEmail() async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userEmailKey);
  }

  static Future<String?> getUserName() async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userNameKey);
  }

  static Future<DateTime? > getDOB() async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    String? dobString = sf.getString(dobKey);
    if (dobString != null) {
      return DateTime.parse(dobString);
    }
    return null;
  }

  static Future<String?> getGender() async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(genderKey);
  }

  static Future<String? > getPhoneNumber() async{
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(phoneNumberKey);
  }


}