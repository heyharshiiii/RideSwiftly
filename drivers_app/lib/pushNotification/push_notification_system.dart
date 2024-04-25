import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
class PushNotificationSystem{
  FirebaseMessaging firebaseCloudMessaging=FirebaseMessaging.instance;

  Future<String?> generateDeviceRegistrationToken() async 
  {
      String? deviceRecognitionToken=await firebaseCloudMessaging.getToken();

      DatabaseReference referenceOnlineDriver=FirebaseDatabase.instance.ref()
      .child("drivers")
      .child(FirebaseAuth.instance.currentUser!.uid)
      .child("deviceToken");

      referenceOnlineDriver.set(deviceRecognitionToken);

      firebaseCloudMessaging.subscribeToTopic("drivers");
      firebaseCloudMessaging.subscribeToTopic("s");
  } 

    startListeningForNewNotification() async
    {
      ///1.Terminated
      //WHEN APP IS completely closed
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? messageRemote){
        if(messageRemote!=null)
        {
          String tripID=messageRemote!.data["tripID"];
        }
      });
      
      ///2.Foreground
      //when app is open and it receives a push notification
      FirebaseMessaging.onMessage.listen((RemoteMessage? messageRemote){
         if(messageRemote!=null)
        {
          String tripID=messageRemote!.data["tripID"];
        }
      });
      
      ///3.BackGround
      //When the app is in the background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? messageRemote){
         if(messageRemote!=null)
        {
          String tripID=messageRemote!.data["tripID"];
        }
      });
    }
}