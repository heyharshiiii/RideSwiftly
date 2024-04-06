import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drivers_app/global/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
   final Completer<GoogleMapController> _googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;

    loadData() {
    getCurrentLiveLocationOfUser().then((value) {
      print("My loc");
      print(value.latitude.toString() + " " + value.longitude.toString());
      _markers.add(Marker(
          markerId: MarkerId('1'),
          position: LatLng(value.latitude, value.longitude),
          infoWindow: InfoWindow(title: 'My Current Location')));
      setState(() {});
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    loadData();
  }

   //update map theme func
  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/dark_style.json")
        .then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asInt8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }


  Future<Position> getCurrentLiveLocationOfUser() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;
    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    return positionOfUser;
  }

  final List<Marker> _markers = <Marker>[];
  @override
  Widget build(BuildContext context) {
     return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            markers: Set<Marker>.of(_markers),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              _googleMapCompleterController.complete(controllerGoogleMap);
            },
          )
        ],
      ),
    );
  }
}