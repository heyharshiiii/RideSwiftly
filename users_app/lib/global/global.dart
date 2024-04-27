import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName="";
String userPhone="";
String userID=FirebaseAuth.instance.currentUser!.uid;
String googleMapKey="AIzaSyCXp7ByOEplT_94XrrwB78tmJSkBXQWOa4";
String locIQApiKey="pk.de81bff2492636d69ea6e6c60ea5f12f";
 const CameraPosition googlePlexInitialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );