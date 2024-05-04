import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:users_app/appInfo/appInfo.dart';
import 'package:users_app/authentication/login_screen.dart';

import 'package:users_app/global/global.dart';
import 'package:users_app/global/trip_var.dart';
import 'package:users_app/methods/common_methods.dart';
import 'package:users_app/methods/manage_drivers_method.dart';
import 'package:users_app/methods/push_notification_system.dart';
import 'package:users_app/models/address_model.dart';
import 'package:users_app/models/direction_details.dart';
import 'package:users_app/models/online_nearby_drivers.dart';
import 'package:users_app/pages/about_page.dart';
import 'package:users_app/pages/search_dest_page.dart';
import 'package:users_app/pages/trips_history_page.dart';
import 'package:users_app/widgets/info_dialog.dart';
import 'package:users_app/widgets/loading_dialog.dart';
import 'package:users_app/widgets/payment_dialog.dart';

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
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  DirectionDetails? tripDirectionDetailsInfo;
  AddressModel? dropOffLocation;
  Position? pickPosition;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  bool isDrawerOpened = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo=false;

  makeDriverNearbyCarIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: Size(0.5, 0.5));
      BitmapDescriptor.fromAssetImage(
              configuration, "assets/images/tracking.png")
          .then((iconImage) {
        carIconNearbyDriver = iconImage;
      });
    }
  }

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
    await initializeGeoFireListener();
    return positionOfUser;
  }

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
          setState(() {
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
          });
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
      LatLng(double.parse(pickUpLocation!.latitudePosition!),
          double.parse(pickUpLocation!.longitudePosition!)),
      LatLng(DobDropOffLat, DobDropOffLng)
    ];

    print("PICK LAT" + pickUpLocation.humanReadableAddress!);
    // print("PICK LAT" + pickUpLocation.longitudePosition!);
    // print("DROP LAT" + dropOffLocation!.latitudePosition!.toString());
    // print("DROP LONG" + dropOffLocation.longitudePosition!.toString());
    // print("PICK NAMEEEEEEEEEE" + XPICK.placeName!);
    // print("Drop NAMEEEEEEEEEE" + dropOffLocation.placeName.toString());

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
      isDrawerOpened = false;
    });
    print("DETAILS!" + tripDirectionDetailsInfo.toString());

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
          southwest: LatLng(DobDropOffLat, DobDropOffLng),
          northeast: LatLng(pickPosition!.latitude, pickPosition!.longitude));
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

    // Circle pickUpPointCircle = Circle(
    //     circleId: CircleId("pickUpCircleID"),
    //     strokeColor: Colors.black,
    //     strokeWidth: 4,
    //     radius: 14,
    //     center: LatLng(pickPosition!.latitude, pickPosition!.longitude),
    //     fillColor: Colors.green);
    // Circle destPointCircle = Circle(
    //     circleId: CircleId("destCircleID"),
    //     strokeColor: Colors.black,
    //     strokeWidth: 4,
    //     radius: 14,
    //     center: LatLng(DobDropOffLat, DobDropOffLng),
    //     fillColor: Colors.blue);

    // setState(() {
    //   // circleSet.add(pickUpPointCircle);
    //   // circleSet.add(destPointCircle);
    // });
  }

  updateAvailableNearbyOnlineDriversonMap() {
    print("updated");
    setState(() {
      markerSet.clear();
    });
    Set<Marker> markersTempSet = Set<Marker>();
    for (OnlineNearbyDrivers eachOnlineNearbyDriver
        in ManageDriversMethods.nearbyOnlineDriversList) {
      LatLng driverCurrentPosition = LatLng(
          eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);
      Marker driverMarker = Marker(
          markerId: MarkerId(
              "driver ID= " + eachOnlineNearbyDriver.uidDriver.toString()),
          position: driverCurrentPosition,
          icon: carIconNearbyDriver!);
      markersTempSet.add(driverMarker);
    }
    setState(() {
      markerSet = markersTempSet;
    });
  }

  initializeGeoFireListener() {
    print("I AM GEO");
    Geofire.initialize("onlineDrivers");
    print("yyyyyyyyy");
    Geofire.queryAtLocation(currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude, 22)!
        .listen((driverEvent) {
      if (driverEvent != null) {
        var onlineDriverChild = driverEvent["callBack"];
        switch (onlineDriverChild) {
          case Geofire.onKeyEntered:
            //display nearest online drivers that gets inside the radius or becomes online
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];

            ManageDriversMethods.nearbyOnlineDriversList
                .add(onlineNearbyDrivers);
            if (nearbyOnlineDriversKeysLoaded == true) {
              //update driver on google map
              updateAvailableNearbyOnlineDriversonMap();
            }
            break;

          case Geofire.onKeyExited:
            //display nearest online drivers that leaves the circle or goes offline
            ManageDriversMethods.removeDriverFromList(driverEvent["key"]);
            //update drivers on google map
            updateAvailableNearbyOnlineDriversonMap();
            break;

          case Geofire.onKeyMoved:
            //display nearest online drivers that is moving within the circle
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.updateOnlineNearbyDriversLocation(
                onlineNearbyDrivers);
            //update driver on google map
            print("laaaaat" + driverEvent["latitude"]);
            updateAvailableNearbyOnlineDriversonMap();
            break;

          case Geofire.onGeoQueryReady:
            //display nearest online drivers which are already there bydefault
            nearbyOnlineDriversKeysLoaded = true;
            //update drivers on google map
            updateAvailableNearbyOnlineDriversonMap();
            break;
        }
      }
    });
  }

  resetAppNow() {
    setState(() {
      polylineCoordinates.clear();
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 76;
      bottomMapPadding = 200;
      isDrawerOpened = true;

      status = "";
      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      carDetailsDriver = "";
      tripStatusDisplay = "Driver is arriving";
    });
    //
  }

  displayRequestContainer() {
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    });

    //send ride request

    makeTripRequest();
  }

  makeTripRequest() {
    tripRequestRef =
        FirebaseDatabase.instance.ref().child("tripRequests").push();
    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;
    Map pickupCoordinatesMap = {
      "latitude": pickUpLocation!.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };
    Map dropOffDestCoordinatesMap = {
      "latitude": dropOffDestLocation!.latitudePosition.toString(),
      "longitude": dropOffDestLocation.longitudePosition.toString(),
    };
    Map driverCoOrdinates = {
      "latitude": "",
      "longitude": "",
    };
    Map dataMap = {
      "tripID": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),
      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickupCoordinatesMap,
      "dropOffLatLng": dropOffDestCoordinatesMap,
      "pickUpAddress": pickUpLocation.humanReadableAddress,
      "dropOffAddress": dropOffDestLocation.placeName,
      "driverId": "waiting",
      "driverLocation": driverCoOrdinates,
      "driverName": "",
      "driverPhone": "",
      //"driverPhoto": "",
      "fareAmount": "",
      "status": "new",
    };

    tripRequestRef!.set(dataMap);
    tripStreamSubscription = tripRequestRef!.onValue.listen((eventSnapshot) async{
      if(eventSnapshot.snapshot.value == null)
      {
        return;
      }

      if((eventSnapshot.snapshot.value as Map)["driverName"] != null)
      {
        nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
      }
     if((eventSnapshot.snapshot.value as Map)["driverPhone"] != null)
      {
        phoneNumberDriver = (eventSnapshot.snapshot.value as Map)["driverPhone"];
      }
        if((eventSnapshot.snapshot.value as Map)["car_Details"] != null)
      {
        carDetailsDriver = (eventSnapshot.snapshot.value as Map)["car_Details"];
      }

      if((eventSnapshot.snapshot.value as Map)["status"] != null)
      {
        status = (eventSnapshot.snapshot.value as Map)["status"];
      }
            if((eventSnapshot.snapshot.value as Map)["driverLocation"] != null)
      {
        double driverLatitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverLongitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"].toString());
        LatLng driverCurrentLocationLatLng = LatLng(driverLatitude, driverLongitude);

        if(status == "accepted")
        {
          //update info for pickup to user on UI
          //info from driver current location to user pickup location
          updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
        }
        else if(status == "arrived")
        {
          //update info for arrived - when driver reach at the pickup point of user
          setState(() {
            tripStatusDisplay = 'Driver has Arrived';
          });
        }
        else if(status == "ontrip")
        {
          //update info for dropoff to user on UI
          //info from driver current location to user dropoff location
          updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng);
        }
      } 
       if(status == "accepted")
      {
        displayTripDetailsContainer();

        Geofire.stopListener();

        //remove drivers markers
        setState(() {
          markerSet.removeWhere((element) => element.markerId.value.contains("driver"));
        });
      }
        if(status == "ended")
      {
        if((eventSnapshot.snapshot.value as Map)["fareAmount"] != null)
        {
          double fareAmount = double.parse((eventSnapshot.snapshot.value as Map)["fareAmount"].toString());

          var responseFromPaymentDialog = await showDialog(
              context: context,
              builder: (BuildContext context) => PaymentDialog(fareAmount: fareAmount.toString()),
          );

          if(responseFromPaymentDialog == "paid")
          {
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;

            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            resetAppNow();

            Restart.restartApp();
          }
        }
      }
    });
  }
    displayTripDetailsContainer()
  {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 300;
      bottomMapPadding = 281;
    });
  }
    updateFromDriverCurrentLocationToDropOffDestination(LatLng driverCurrentLocationLatLng) async
  {
    if(!requestingDirectionDetailsInfo)
    {
      requestingDirectionDetailsInfo = true;

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;
      var pickUpLocation= Provider.of<AppInfo>(context, listen: false).pickUpLocation;
      //var userDropOffLocationLatLng = LatLng( double.parse(dropOffLocation!.latitudePosition!), double.parse(dropOffLocation!.longitudePosition!));

      var directionDetailsPickup = await CommonMethods.getDirectionDetailsFromAPI(double.parse(pickUpLocation!.longitudePosition!) , double.parse(pickUpLocation.longitudePosition!),
      dropOffLocation!.longitudePosition! ,dropOffLocation.latitudePosition!);

      if(directionDetailsPickup == null)
      {
        return;
      }

      setState(() {
      //  String x=(directionDetailsPickup.durationValueDigits!/60).toStringAsFixed(2);
        tripStatusDisplay = "Driving to DropOff Location - ${tripDirectionDetailsInfo!.durationValueDigits!}mins";
      });

      requestingDirectionDetailsInfo = false;
    }
  }
   updateFromDriverCurrentLocationToPickUp(LatLng driverCurrentLocationLatLng) async
  {
    if(!requestingDirectionDetailsInfo)
    {
      requestingDirectionDetailsInfo = true;
var pickUpLocation= Provider.of<AppInfo>(context, listen: false).pickUpLocation;
     // var userPickUpLocationLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      var directionDetailsPickup = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng.longitude,driverCurrentLocationLatLng.latitude,
      pickUpLocation!.longitudePosition! ,pickUpLocation.longitudePosition!);

      if(directionDetailsPickup == null)
      {
        return;
      }

      setState(() {
        String x=(directionDetailsPickup.durationValueDigits!/60).toStringAsFixed(2);
        tripStatusDisplay = "Driver is Coming";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  cancelRideRequest() {
    //remove ride request from database
    tripRequestRef!.remove();
    setState(() {
      stateOfApp = "normal";
    });
  }

  noDriverAvailable() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => InfoDialog(
              title: "No Driver Available",
              description:
                  "No driver found in nearby location. Please try again shortly",
            ));
  }

  searchDriver() {
    //print("AVAILAAAAAAABLE"+availableNearbyOnlineDriversList);
    if (availableNearbyOnlineDriversList!.isEmpty) {
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    } else {
      var currentDriver = availableNearbyOnlineDriversList![0];
      //send notification to this currentDriver --> SELECTED DRIVER
      sendNotificationToDriver(currentDriver);
      availableNearbyOnlineDriversList!.removeAt(0);
    }
    print(availableNearbyOnlineDriversList);
    //remove ride request from database
    //tripRequestRef!.remove();
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    //update driver's newtrip status
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus"); //travel till this point
    currentDriverRef.set(tripRequestRef!.key);

    //get current driver registration token
    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");
    tokenOfCurrentDriverRef.once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        String deviceToken = dataSnapshot.snapshot.value.toString();

        //SEND NOTIFICATION
        PushNotificationService.sendNotificationToSelectedDriver(
            deviceToken, context, tripRequestRef!.key.toString());
      } else {
        return;
      }
      const oneTickPerSec = Duration(seconds: 1);
      var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
        requestTimeOutDriver -= 1;

        //when trip request is not requesting means trip request cancelled - stop timer
        if (stateOfApp != "requesting") {
          timer.cancel();
          currentDriverRef.set("cancelled");
          currentDriverRef.onDisconnect();
          requestTimeOutDriver = 20;
        }
        //when trip request is accepted by online nearest driver driver
        currentDriverRef.onValue.listen((dataSnapshot) {
          if (dataSnapshot.snapshot.value.toString() == "accepted") {
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeOutDriver = 20;
          }
        });
        //if 20 seconds passed - send notification to next nearby online driver
        if (requestTimeOutDriver == 0) {
          currentDriverRef.set("timeout");
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeOutDriver = 20;
          //send notification to next nearby online driver
          searchDriver();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    makeDriverNearbyCarIcon();
    return Scaffold(
      key: sKey,
      drawer: DrawerWidget(),
      body: Stack(
        children: [
          GoogleMapWidget(),

          //drawer button
          MenuIconWidget(),

          SearchWorkHomeWidget(context),

          RideDetailsContainerWidget(context),

          //request container
          RequestContainerWidget(),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.white24,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 5,),

                    //trip status display text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tripStatusDisplay,
                          style: const TextStyle(fontSize: 19, color: Colors.grey,),
                        ),
                    
                      ],
                    ),
const SizedBox(height: 19,),

                    const Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),

                    const SizedBox(height: 19,),

                    //image - driver name and driver car details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        ClipOval(
                          child: Image.network(
                            photoDriver == ''
                                ? "https://firebasestorage.googleapis.com/v0/b/rideswiftly-ceb15.appspot.com/o/avatarwoman.webp?alt=media&token=be67a00c-ef32-4bf5-a532-79a490985501"
                                : photoDriver,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
const SizedBox(width: 8,),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(nameDriver, style: const TextStyle(fontSize: 20, color: Colors.grey,),),

                            Text(carDetailsDriver, style: const TextStyle(fontSize: 14, color: Colors.grey,),),

                          ],
                        ),

                      ],
                    ),

                    const SizedBox(height: 19,),

                    const Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),

                    const SizedBox(height: 19,),

                    //call driver btn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          GestureDetector(
                          onTap: ()
                          {
                            launchUrl(Uri.parse("tel://$phoneNumberDriver"));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 11,),

                              const Text("Call", style: TextStyle(color: Colors.grey,),),

                            ],
                             ),
                        ),

                      ],
                    ),

                  ],
            
            
                )))
            )
        ],
      ),
    );
  }

  Positioned RequestContainerWidget() {
    return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          height: requestContainerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15.0,
                spreadRadius: 0.5,
                offset: Offset(0.7, 0.7),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 12,
                ),
                SizedBox(
                  width: 200,
                  child: LoadingAnimationWidget.flickr(
                      leftDotColor: Colors.greenAccent,
                      rightDotColor: Colors.pinkAccent,
                      size: 50),
                ),
                SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () {
                    resetAppNow();
                    cancelRideRequest();
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          width: 1.5,
                          color: const Color.fromRGBO(158, 158, 158, 1)),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }

  Positioned RideDetailsContainerWidget(BuildContext context) {
    return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          height: rideDetailsContainerHeight,
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(15)),
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                onTap: () {
                                  setState(() {
                                    stateOfApp = "requesting";
                                  });
                                  displayRequestContainer();
                                  //get nearest available online driver
                                  availableNearbyOnlineDriversList =
                                      ManageDriversMethods
                                          .nearbyOnlineDriversList;
                                  // if(availableNearbyOnlineDriversList!.isEmpty)
                                  print("AVAILLL" +
                                      availableNearbyOnlineDriversList
                                          .toString());

                                  //search driver
                                  searchDriver();
                                },
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
        ));
  }

  Positioned SearchWorkHomeWidget(BuildContext context) {
    return Positioned(
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
                  AddressModel responseFromSearchPage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SearchDestinationPage()));
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
    );
  }

  Positioned MenuIconWidget() {
    return Positioned(
      top: 36,
      left: 19,
      child: GestureDetector(
        onTap: () {
          if (isDrawerOpened == true) {
            sKey.currentState!.openDrawer();
          } else {
            resetAppNow();
          }
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
          child: CircleAvatar(
            backgroundColor: Colors.grey,
            radius: 20,
            child: Icon(
              isDrawerOpened == true ? Icons.menu : Icons.close,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  GoogleMap GoogleMapWidget() {
    return GoogleMap(
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
    );
  }

  Container DrawerWidget() {
    return Container(
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
                    Image.asset("assets/images/avatarwoman.png",width: 60,height: 60,),
                
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

             GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (c)=> TripsHistoryPage()));
              },
              child: ListTile(
                leading: IconButton(
                  onPressed: () {
                     
                  },
                  icon: const Icon(
                    Icons.history_outlined,
                    color: Colors.grey,
                  ),
                ),
                title: const Text(
                  "Trips History",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (c)=> AboutPage()));
              },
              child: ListTile(
                leading: IconButton(
                  onPressed: () {
                     
                  },
                  icon: const Icon(
                    Icons.info,
                    color: Colors.grey,
                  ),
                ),
                title: const Text(
                  "About Developer",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                _signOut();

                // Navigator.push(context, MaterialPageRoute(builder: (c)=> AboutPage()));
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
    );
  }
}
