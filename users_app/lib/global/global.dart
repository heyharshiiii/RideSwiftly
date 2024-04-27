import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName="";
String userPhone="";
String userID=FirebaseAuth.instance.currentUser!.uid;
String googleMapKey="AIzaSyCXp7ByOEplT_94XrrwB78tmJSkBXQWOa4";
String locIQApiKey="pk.de81bff2492636d69ea6e6c60ea5f12f";
String serverKeyFCM="key=AAAAJitzrlI:APA91bG8nLlL0y7VaGY4X2oltztSORp39mr_qx4QIqJWa4X9p127mwdk5dLzFc6Mo8xzxektjtBW4MaOoSlkO-Az0r8LTZLTHI0EeCjVr1OQKmigeztS93K5hCLcqcQILLKMn0biz1ZM";
 const CameraPosition googlePlexInitialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );