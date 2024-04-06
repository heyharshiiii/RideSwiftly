import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:users_app/appInfo/appInfo.dart';
import 'package:users_app/authentication/login_screen.dart';
import 'package:users_app/authentication/signup_screen.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/methods/common_methods.dart';
import 'package:users_app/models/address_model.dart';
import 'package:users_app/models/direction_details.dart';
import 'package:users_app/pages/search_dest_page.dart';
import 'package:users_app/widgets/loading_dialog.dart';

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
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  CommonMethods cMethods = CommonMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double searchContainerHeight = 76;
  double bottomMapPadding = 0;
  double rideDetailsContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  AddressModel? dropOffLocation;
  Position? pickPosition;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};

  loadData() {
    //await getUserInfoAndCheckBlockStatus();
    getCurrentLiveLocationOfUser().then((value) {
      print("My loc");
      print(value.latitude.toString() + " " + value.longitude.toString());

      //setState(() {});
    });
    //getUserInfoAndCheckBlockStatus();
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
    pickPosition = positionOfUser;
    LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    print("curr lat=" + currentPositionOfUser!.latitude.toString());
    print("curr lat=" + currentPositionOfUser!.longitude.toString());
    await CommonMethods.convertCoordinatesToHumanReadable(
        currentPositionOfUser!, context);
    await getUserInfoAndCheckBlockStatus();
    return positionOfUser;
  }

  final List<Marker> _markers = <Marker>[];

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  getUserInfoAndCheckBlockStatus() async {
    DatabaseReference usersRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid);
    await usersRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
          userName = (snap.snapshot.value as Map)["name"];
        } else {
          _signOut();
          cMethods.displaySnackBar(
              "You are blocked. Contact admin harshita@gmail.com", context);
        }
      } else {
        _signOut();
      }
    });
  }

  // displayUserRideDetailsContainer() async{
  //   var pickUpLocation= Provider.of<AppInfo>(context,listen:false).pickUpLocation;
  //    // var dropOffLocation= Provider.of<AppInfo>(context,listen:false).dropOffLocation;

  // // print("PICK LAT"+pickPosition!.latitude.toString());
  // // print("PICK LAT"+pickPosition!.longitude.toString() );
  // // print("DROP LAT"+dropOffLocation!.latitudePosition!);
  // // print("DROP LONG"+dropOffLocation!.longitudePosition!);
  // await retrieveDirectionDetails();
  // print(  retrieveDirectionDetails());
  //   //draw route between pickup and dest location

  // }

  retrieveDirectionDetails(AddressModel dropOffLocation) async {
    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    //var dropOffLocation= Provider.of<AppInfo>(context,listen:false).dropOffLocation;
    double DobDropOffLat = double.parse(dropOffLocation.latitudePosition!);
    double DobDropOffLng = double.parse(dropOffLocation.longitudePosition!);
    List<LatLng> latlng = [
      LatLng(double.parse(pickUpLocation!.latitudePosition!), double.parse(pickUpLocation!.longitudePosition!)),
      LatLng(DobDropOffLat, DobDropOffLng)
    ];

    print("PICK LAT" + pickPosition!.latitude.toString());
    print("PICK LAT" + pickPosition!.longitude.toString());
    print("DROP LAT" + dropOffLocation!.latitudePosition!.toString());
    print("DROP LONG" + dropOffLocation.longitudePosition!.toString());
    print("PICK NAMEEEEEEEEEE" + pickUpLocation!.placeName.toString());
    print("Drop NAMEEEEEEEEEE" + dropOffLocation.placeName.toString());

    // var pickupGeographicCoord=LatLng(pickUpLocation!.laPosition as double, pickUpLocation.longitudePosition as double);
    // var dropOffGeographicCoord=LatLng(dropOffLocation!.longitudePosition as double, dropOffLocation.longitudePosition as double);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Getting Direction..."));
    var detailsFromDirectionAPI =
        await CommonMethods.getDirectionDetailsFromAPI(
            pickPosition!.longitude,
            pickPosition!.latitude,
            dropOffLocation.longitudePosition,
            dropOffLocation.latitudePosition);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });
    setState(() {
      searchContainerHeight = 0;
      bottomMapPadding = 300;
      rideDetailsContainerHeight = 240;
    });
    print("DETAILS!" + tripDirectionDetailsInfo.toString());

    // for (int i = 0; i < 2; i++) {
    //   markerSet.add(
    //     Marker(
          
    //       markerId: MarkerId(i.toString()),
    //       position: latlng[i],
    //       icon:
    //           (latlng[i]==latlng[0])? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow):BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    //       infoWindow:
    //           InfoWindow(title: pickUpLocation.placeName, snippet: "Location"),
    //     ),
    //   );
      
    //   polylineSet.add(Polyline(
    //   polylineId: PolylineId('1'),
    //   color: Colors.blue,
    //   points: latlng
    // ));
    // }
    

     Navigator.pop(context);

    ///DRAWING ROUTE USING POLYLINE
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latlngfromPickuptoDest =
        pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);
    print(latlngfromPickuptoDest);
    polylineCoordinates.clear();
    if (latlngfromPickuptoDest.isNotEmpty) {
      latlngfromPickuptoDest.forEach((PointLatLng latLngpoint) {
        polylineCoordinates
            .add(LatLng(latLngpoint.latitude, latLngpoint.longitude));
      });
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
          polylineId: PolylineId("polylineID"),
          color: Colors.red,
          points: polylineCoordinates,
          jointType: JointType.round,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);

      polylineSet.add(polyline);
    });

    //FIT POLYLINE INTO MAP

    LatLngBounds boundsLatLng;
   
    if (pickPosition!.latitude! > DobDropOffLat &&
        pickPosition!.longitude! > DobDropOffLng) {
      boundsLatLng = LatLngBounds(
          southwest:LatLng(DobDropOffLat, DobDropOffLng),
          northeast:  LatLng(pickPosition!.latitude, pickPosition!.longitude));
    } else if (pickPosition!.longitude! > DobDropOffLng) {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(pickPosition!.latitude, DobDropOffLng),
          northeast: LatLng(DobDropOffLat, pickPosition!.longitude));
    } else if (pickPosition!.latitude! > DobDropOffLat) {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(DobDropOffLat, pickPosition!.longitude),
          northeast: LatLng(pickPosition!.latitude, DobDropOffLng));
    } else {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(pickPosition!.latitude, pickPosition!.longitude),
          northeast: LatLng(DobDropOffLat, DobDropOffLng));
    }

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //ADD MARKERSSSSSSS

    
    Marker pickUpPointMarker = Marker(
        markerId: MarkerId("pickUpPointMarkerID"),
        position: LatLng(pickPosition!.latitude, pickPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: pickUpLocation.placeName, snippet: "Location"));

    Marker destPointMarker = Marker(
        markerId: MarkerId("destPointMarkerID"),
        position: LatLng(DobDropOffLat, DobDropOffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow:
            InfoWindow(title: dropOffLocation.placeName, snippet: "Location"));

    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(destPointMarker);
    });

    Circle pickUpPointCircle = Circle(
      circleId: CircleId(
        "pickUpCircleID"),
        strokeColor: Colors.black,
        strokeWidth: 4,
        radius: 14,
        center: LatLng(pickPosition!.latitude, pickPosition!.longitude),
        fillColor: Colors.green
    );
Circle destPointCircle = Circle(
      circleId: CircleId(
        "destCircleID"),
        strokeColor: Colors.black,
          strokeWidth: 4,
          radius: 14,
          center:  LatLng(DobDropOffLat,DobDropOffLng),
          fillColor: Colors.blue
      );

      setState(() {
        // circleSet.add(pickUpPointCircle);
        // circleSet.add(destPointCircle);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.black87,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [
              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),
//header
              Container(
                color: Colors.black54,
                height: 160,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/avatarman.png",
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(
                height: 1,
                color: Colors.grey,
                thickness: 1,
              ),

              const SizedBox(
                height: 10,
              ),

              //body
              ListTile(
                leading: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.info,
                    color: Colors.grey,
                  ),
                ),
                title: const Text(
                  "About",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              GestureDetector(
                onTap: () {
                  _signOut();

                  // Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            //cloudMapId: ,
            padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
            //markers: Set<Marker>.of(_markers),
            polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              _googleMapCompleterController.complete(controllerGoogleMap);
              setState(() {
                bottomMapPadding = 100;
              });
            },
          ),
          //drawer button
          Positioned(
            top: 36,
            left: 19,
            child: GestureDetector(
              onTap: () {
                sKey.currentState!.openDrawer();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                  child: Icon(
                    Icons.menu,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Container(
              height: searchContainerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(24),
                          backgroundColor: Colors.grey),
                      onPressed: () async {
                        AddressModel responseFromSearchPage =
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SearchDestinationPage()));
                        dropOffLocation = responseFromSearchPage;

                        Provider.of<AppInfo>(context, listen: false)
                            .updateDropOffLocation(dropOffLocation!);
                        print("DROP OFF LOCATION:   " +
                            dropOffLocation!.placeName.toString());
                        if (dropOffLocation != 'x') {
                          retrieveDirectionDetails(dropOffLocation!);
                        }
                      },
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 25,
                      )),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(24),
                          backgroundColor: Colors.grey),
                      onPressed: () {},
                      child: Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 25,
                      )),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(24),
                          backgroundColor: Colors.grey),
                      onPressed: () {},
                      child: Icon(
                        Icons.work,
                        color: Colors.white,
                        size: 25,
                      ))
                ],
              ),
            ),
          ),
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(15)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.white12,
                          blurRadius: 15.0,
                          spreadRadius: 0.5,
                          offset: Offset(.7, .7))
                    ]),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: SizedBox(
                          height: 200,
                          child: Card(
                            elevation: 10,
                            child: Container(
                              // height: rideDetailsContainerHeight,
                              width: MediaQuery.of(context).size.width * 0.8,
                              color: Colors.black45,
                              child: Padding(
                                padding: EdgeInsets.only(top: 8.0, bottom: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          (tripDirectionDetailsInfo != null)
                                              ? (tripDirectionDetailsInfo!
                                                              .distanceValueDigits! /
                                                          1000)
                                                      .toStringAsFixed(2) +
                                                  " Km"
                                              : "0km",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          width: 50,
                                        ),
                                        Text(
                                          (tripDirectionDetailsInfo != null)
                                              ? (tripDirectionDetailsInfo!
                                                              .durationValueDigits! /
                                                          60)
                                                      .toStringAsFixed(2) +
                                                  " mins"!
                                              : "0km",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),

                                    //Text(dropOffLocation!.placeName.toString().split(" ")[0]),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Image.asset(
                                        "assets/images/uberexec.png",
                                        height: 122,
                                        width: 122,
                                      ),
                                    ),
                                    Text(
                                      (tripDirectionDetailsInfo != null)
                                          ? "\$" +
                                              (cMethods.calculateFareAmount(
                                                      tripDirectionDetailsInfo!))
                                                  .toString()
                                          : "\$0",
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
