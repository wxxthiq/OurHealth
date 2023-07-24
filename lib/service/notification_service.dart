import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:ourhealth/pages/call_page.dart';


class NotificationService {
  String? myToken = "";
  static BuildContext? appContext; // Store the app context here

  void getToken() async {
    myToken = await FirebaseMessaging.instance.getToken();
    //saveToken(token!);
  }

  static void sendCallNotification(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AAAAuYBVL6Y:APA91bHLaw_CJNEuDlaE9nK1UYemvvUIocCDtVgsh696Jj9EzWIOO8w8T_tljBjuZ3gMVfxll8U1Ivg7cbORw-sSOLYx7GvmAGbYLgf7B7xJVBbx5GZgFsrnZGWvjPFraesAhhCgGSc2',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': body,
              'title': title,
            },
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
              'id': '1',
              'android': {
                'priority': 'high',
                'notification': {
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'title': title,
                  'body': body,
                },
              },
            },
            'to': token,
          },
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error with push notifications');
      }
    }
  }


  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    String? title = message.notification!.title;
    String? body = message.notification!.body;

    AwesomeNotifications().createNotification(content: NotificationContent(
      id: 1,
      channelKey: 'high_importance_channel',
      color: Colors.white,
      title: title,
      body: body,
      category: NotificationCategory.Call,
      wakeUpScreen: true,
      fullScreenIntent: true,
    ),
        actionButtons: [
          NotificationActionButton(
            key: "$body",
            label: "Accept Call",
            color: Colors.green,
            autoDismissible: true,
              actionType: ActionType.SilentAction,

          ),

          NotificationActionButton(
            key: "Decline",
            label: "Decline Call",
            color: Colors.red,
            autoDismissible: true,
            actionType: ActionType.DisabledAction,
          ),
        ]
    );
    // Handle the notification actions
    // AwesomeNotifications().actionStream.listen((receivedNotification) {
    //   if (receivedNotification.buttonKeyPressed == 'ACCEPT') {
    //     // Perform your page navigation here
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) => AcceptCallScreen()),
    //     );
    //   } else if (receivedNotification.buttonKeyPressed == 'DECLINE') {
    //     // Handle the 'Decline' button action
    //     // ...
    //   }
    // });
   // AwesomeNotifications().setListeners(onActionReceivedMethod: callHandler);

  }

  @pragma("vm:entry-point")
  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: callHandler);
  }
  static Future<void> callHandler(ReceivedAction call)async {
    if (call.actionType == ActionType.Default) {
      print("what is it "+ call.buttonKeyPressed);
        if (call.buttonKeyPressed == "Incoming Audio Call" ) {
          Navigator.push(
            appContext!,
            MaterialPageRoute(builder: (context) =>
                callPage(
                  isCaller: false,
                  callType: "Audio call")
            ),
          );
        }else if (call.buttonKeyPressed == "Incoming Video Call" ) {
          Navigator.push(
            appContext!,
            MaterialPageRoute(builder: (context) =>
                callPage(
                    isCaller: false,
                    callType: "Video call")
            ),
          );
        }
        else if (call.buttonKeyPressed == 'Decline') {
        }
    }
  }
  static Future<void> initializeNotifications(String email,BuildContext context) async {

    appContext = context;
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');


    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("tokens")
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isEmpty) {
      // No documents found, create a new record
      await FirebaseFirestore.instance.collection("tokens").add({
        'email': email,
        'token': token,
      });
    } else {
      // Update existing documents
      querySnapshot.docs.forEach((doc) {
        doc.reference.update({
          'token': token,
        });
      });
    }

    AwesomeNotifications().initialize(
      // Set the 'default_icon' to the name of your app icon file located in the 'mipmap' folder.
      null,
      [
        NotificationChannel(
          channelKey: 'high_importance_channel',
          channelName: 'High Importance Notifications',
          channelDescription: 'This channel is used for high importance notifications',
          importance: NotificationImportance.High,
          ledColor: Colors.white
        ),
      ],
    );
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  foregroundHandler();



    // const AndroidNotificationChannel channel = AndroidNotificationChannel(
    //   'high_importance_channel', // id
    //   'High Importance Notifications', // title
    //   'This channel is used for important notifications.', // description
    //   importance: Importance.max,
    // );

    // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    // FlutterLocalNotificationsPlugin();
    //
    // await flutterLocalNotificationsPlugin
    //     .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    //     ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message){
      String? title = message.notification!.title;
      String? body = message.notification!.body;

      AwesomeNotifications().createNotification(content: NotificationContent(
        id: 1,
        channelKey: 'high_importance_channel',
        color: Colors.white,
        title: title,
        body: body,
        category: NotificationCategory.Call,
        wakeUpScreen: true,
        fullScreenIntent: true,
      ),
          actionButtons: [
            NotificationActionButton( //during testing, i noticed the latest body it took was this one
              key: "$body",
              label: "Accept Call",
              color: Colors.green,
              autoDismissible: true,),

            NotificationActionButton(
              key: "Decline",
              label: "Decline Call",
              color: Colors.red,
              autoDismissible: true,),
          ]
      );
    });

    AwesomeNotifications().setListeners(onActionReceivedMethod: callHandler);
  }

  static Future <void> backgroundHandler () async{
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  static Future <void> foregroundHandler () async{
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }

 static void handleMessage(RemoteMessage? message){
       // Navigator.push(
       //   appContext!,
       //   MaterialPageRoute(builder: (context) => callPage()),
       // );
 }
}
