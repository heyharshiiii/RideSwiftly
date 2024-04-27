import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:users_app/appInfo/appInfo.dart';
import 'package:users_app/global/global.dart';
import 'package:http/http.dart' as http;

class PushNotificationService
{ 
  static sendNotificationToSelectedDriver(String deviceToken,BuildContext context,String tripID) async
  {
    String dropOffdestAddress=Provider.of<AppInfo>(context,listen: false).dropOffLocation!.placeName.toString();
    String pickupAddress=Provider.of<AppInfo>(context,listen: false).pickUpLocation!.humanReadableAddress.toString();
    Map<String,String> headerNotificationMap=
    {
      "Content-Type":"application/json",
      "Authorization":serverKeyFCM
    };

    Map titleBodyNotificationMap=
    {
      "title":"NEW TRIP REQUEST FROM $userName",
      "body":"Pick Up:$pickupAddress \n Drop off: $dropOffdestAddress"
    };
    Map dataMapNotification=
    {
      "click_action":"FLUTTER_NOTIFICATION_CLICK",
      "id":1,
      "status":"done",
      "tripID":tripID
    };

    Map bodyNotificationMap=
    {
        "notification":titleBodyNotificationMap,
        "data":dataMapNotification,
        "priority":"high",
        "to":deviceToken
    };
    await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headerNotificationMap,
      body: jsonEncode(bodyNotificationMap),

    );
  }
}