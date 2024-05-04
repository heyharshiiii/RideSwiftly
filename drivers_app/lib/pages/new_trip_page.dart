import 'dart:async';

import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/methods/common_methods.dart';
import 'package:drivers_app/methods/map_theme_methods.dart';
import 'package:drivers_app/models/trip_details.dart';
import 'package:drivers_app/widgets/loading_dialog.dart';
import 'package:drivers_app/widgets/payment_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NewTripPage extends StatefulWidget {
  TripDetails? newTripDetailsInfo;

  NewTripPage({
    super.key,
    this.newTripDetailsInfo,
  });

  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage> {
  final Completer<GoogleMapController> _googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  MapThemeMethods mapThemeMethods = MapThemeMethods();
  double googleMapPaddingFromBottom = 0;
  List<LatLng> coordinatesPolylineLatLng = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Set<Marker> markersSet = Set<Marker>();
  Set<Marker> circleSet = Set<Marker>();
  Set<Polyline> polylineSet = Set<Polyline>();
  BitmapDescriptor? carMarkerIcon;
  bool directionRequested = false;
  String statusOfTrip = "accepted";
  String durationText = "";
  String distanceText = "";
  String buttonTitleText = "ARRIVED";
  Color buttonColor = Colors.indigoAccent;
  CommonMethods cmethods = CommonMethods();
  makeMarker() {
    if (carMarkerIcon == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              configuration, "assets/images/tracking.png")
          .then((iconImage) {
        carMarkerIcon = iconImage;
      });
    }
  }

  obtainDirectionAndDrawRoute(
      LatLng sourceLocationLatLng, LatLng destinationLocationLatLng) async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Please Wait"));

    var tripDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
        sourceLocationLatLng.longitude,
        sourceLocationLatLng.latitude,
        destinationLocationLatLng.longitude,
        destinationLocationLatLng.latitude);

    print("GOT DETAILS");

    Navigator.pop(context);
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPoints =
        pointsPolyline.decodePolyline(tripDetailsInfo!.encodedPoints!);

    coordinatesPolylineLatLng.clear();
    if (latLngPoints.isNotEmpty) {
      latLngPoints.forEach((PointLatLng pointLatLng) {
        coordinatesPolylineLatLng
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    //draw polyline
    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
          polylineId: PolylineId("routeID"),
          color: Colors.amber,
          points: coordinatesPolylineLatLng,
          jointType: JointType.round,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);
      polylineSet.add(polyline);
    });

    //FIT POLYLINE INTO MAP

    LatLngBounds boundsLatLng;

    if (sourceLocationLatLng.latitude > destinationLocationLatLng.latitude &&
        sourceLocationLatLng.longitude > destinationLocationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
          southwest: destinationLocationLatLng,
          northeast: sourceLocationLatLng);
    } else if (sourceLocationLatLng.longitude >
        destinationLocationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(sourceLocationLatLng.latitude,
              destinationLocationLatLng.longitude),
          northeast: LatLng(destinationLocationLatLng.latitude,
              sourceLocationLatLng.longitude));
    } else if (sourceLocationLatLng.latitude >
        destinationLocationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(destinationLocationLatLng.latitude,
              sourceLocationLatLng.longitude),
          northeast: LatLng(sourceLocationLatLng.latitude,
              destinationLocationLatLng.longitude));
    } else {
      boundsLatLng = LatLngBounds(
          southwest: sourceLocationLatLng,
          northeast: destinationLocationLatLng);
    }

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //ADD MARKERSSSSSSS
    Marker sourceMarker = Marker(
      markerId: MarkerId("sourceID"),
      position: sourceLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destMarker = Marker(
      markerId: MarkerId("destPointMarkerID"),
      position: destinationLocationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    setState(() {
      markersSet.add(sourceMarker);
      markersSet.add(destMarker);
    });
  }

  getLiveLocationUpdatesOfDriver() {
    LatLng lastPositionLatLng = LatLng(0, 0);
    positionStreamNewTripPage =
        Geolocator.getPositionStream().listen((Position positionDriver) {
      driverCurrentPosition = positionDriver;
      LatLng driverCurrentLocationLatLng = LatLng(
          driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
      Marker carMarker = Marker(
        markerId: MarkerId("carMarkerID"),
        position: driverCurrentLocationLatLng,
        icon: carMarkerIcon!,
      );
      setState(() {
        CameraPosition cameraPosition =
            CameraPosition(target: driverCurrentLocationLatLng, zoom: 16);
        controllerGoogleMap!
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markersSet
            .removeWhere((element) => element.markerId.value == "carMarkerID");
        markersSet.add(carMarker);
      });
      lastPositionLatLng = driverCurrentLocationLatLng;
      //update trip details info
      updateTripDetailsInfo();
      //update  driver location tripRequest
      Map updatedLocationOfDriver = {
        "latitude": driverCurrentPosition!.latitude,
        "longitude": driverCurrentPosition!.longitude,
      };
      FirebaseDatabase.instance
          .ref()
          .child("tripRequests")
          .child(widget.newTripDetailsInfo!.tripID!)
          .child("driverLocation")
          .set(updatedLocationOfDriver);
    });
  }

  updateTripDetailsInfo() async {
    if (!directionRequested) {
      directionRequested = true;
      if (driverCurrentPosition == null) return;

      var driverCurrentLocationLatLng = LatLng(
          driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      LatLng dropOffDestinationLocationLatLng;
      if (statusOfTrip == "accepted") {
        dropOffDestinationLocationLatLng =
            widget.newTripDetailsInfo!.pickUpLatLng!;
      } else {
        dropOffDestinationLocationLatLng =
            widget.newTripDetailsInfo!.dropOffLatLng!;
      }
      var directionDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
          driverCurrentLocationLatLng.longitude,
          driverCurrentLocationLatLng.latitude,
          dropOffDestinationLocationLatLng.longitude,
          dropOffDestinationLocationLatLng.latitude);
      // print("DIST TEXT"+directionDetailsInfo!.distanceValueDigits.toString());
      // print("Duration TEXT"+directionDetailsInfo.durationValueDigits.toString());
      double? x = directionDetailsInfo!.distanceValueDigits!;
      x /= 1000;
      double? y = directionDetailsInfo.durationValueDigits!;
      y /= 60;
      if (directionDetailsInfo != null) {
        directionRequested = false;
        setState(() {
          durationText = y!.toStringAsFixed(2) + "mins";
          distanceText = x!.toStringAsFixed(2) + "km";
        });
      }
    }
  }

  endTripNow() async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Please Wait!!"));
    // var driverCurrentLocationLatLng = LatLng(
    //     driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
    var directionDetailsEndInfo =
        await CommonMethods.getDirectionDetailsFromAPI(
            widget.newTripDetailsInfo!.pickUpLatLng!.longitude,
            widget.newTripDetailsInfo!.pickUpLatLng!.latitude,
            widget.newTripDetailsInfo!.dropOffLatLng!.longitude,
            widget.newTripDetailsInfo!.dropOffLatLng!.longitude);
    Navigator.pop(context);

    String fareAmount =
        (cmethods.calculateFareAmount(directionDetailsEndInfo!));
    FirebaseDatabase.instance
        .ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("fareAmount")
        .set(fareAmount);

    FirebaseDatabase.instance
        .ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("status")
        .set("ended");

    positionStreamNewTripPage!.cancel();
//dialog for collecting fare amount
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PaymentDialog(fareAmount: fareAmount),
    );

    //save fare amount to driver total earnings
    saveFareAmountToDriverTotalEarnings(fareAmount);
  }

  saveFareAmountToDriverTotalEarnings(String fareAmount) async {
    DatabaseReference driverEarningsRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("earnings");

    await driverEarningsRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        double previousTotalEarnings =
            double.parse(snap.snapshot.value.toString());
        double fareAmountForTrip = double.parse(fareAmount);

        double newTotalEarnings = previousTotalEarnings + fareAmountForTrip;

        driverEarningsRef.set(double.parse(newTotalEarnings.toStringAsFixed(2)));
      } else {
        driverEarningsRef.set(fareAmount);
      }
    });
  }

 saveDriverDataToTripinfo() async {
    Map<String,dynamic> driverDataMap = {
      "status": "accepted",
      "driverID": FirebaseAuth.instance.currentUser!.uid,
      "driverName": driverName,
      "driverPhone": driverPhone,
      "car_Details": carColor + " - " + carModel + " - " + carNumber
    };

      Map<String,dynamic> driverCurrentLocation = {
      "latitude": driverCurrentPosition!.latitude.toString(),
      "longitude": driverCurrentPosition!.longitude.toString()
    };
    await FirebaseDatabase.instance
        .ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .update(driverDataMap);
    await FirebaseDatabase.instance
        .ref()
        .child("tripRequests")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("driverLocation")
        .update(driverCurrentLocation);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    saveDriverDataToTripinfo();
  }

  @override
  Widget build(BuildContext context) {
    print("PICK UP LAT" +
        widget.newTripDetailsInfo!.pickUpLatLng!.latitude!.toString());
    print("PICK UP LNG" +
        widget.newTripDetailsInfo!.pickUpLatLng!.longitude!.toString());
    print("DROP LNG" +
        widget.newTripDetailsInfo!.dropOffLatLng!.latitude!.toString());
    print("DROP LNG" +
        widget.newTripDetailsInfo!.dropOffLatLng!.longitude!.toString());

    makeMarker();
    return Scaffold(
        body: Stack(children: [
      GoogleMap(
        markers: markersSet,
        //markers: Set<Marker>.of(_markers),
        polylines: polylineSet,
        padding: EdgeInsets.only(bottom: googleMapPaddingFromBottom),
        mapType: MapType.normal,
        myLocationButtonEnabled: true,
        initialCameraPosition: googlePlexInitialPosition,
        onMapCreated: (GoogleMapController mapController) async {
          controllerGoogleMap = mapController;
          mapThemeMethods.updateMapTheme(controllerGoogleMap!);
          _googleMapCompleterController.complete(controllerGoogleMap);
          setState(() {
            googleMapPaddingFromBottom = 262;
          });
          LatLng driverCurrentLocationLatLng = LatLng(
              driverCurrentPosition!.latitude,
              driverCurrentPosition!.longitude);
          LatLng? userPickUpLocationLatLng =
              widget.newTripDetailsInfo!.pickUpLatLng;
          await obtainDirectionAndDrawRoute(
              driverCurrentLocationLatLng, userPickUpLocationLatLng!);
          getLiveLocationUpdatesOfDriver();
        },
      ),

      //trip details
      Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(17), topLeft: Radius.circular(17)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 17,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7),
                )
              ],
            ),
            height: 250,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      durationText + " - " + distanceText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),

                  // user name - call user icon btn
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.newTripDetailsInfo!.userName!,
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      //call user icon btn
                      GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse(
                                "tel://${widget.newTripDetailsInfo!.userPhone.toString()}"));
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Icon(
                              Icons.phone_android_outlined,
                              color: Colors.grey,
                            ),
                          )),
                    ],
                  ),

                  //pickUp icon and location
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/initial.png",
                        height: 16,
                        width: 16,
                      ),
                      Expanded(
                        child: Text(
                          widget.newTripDetailsInfo!.pickUpAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  //dropoff icon and location
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/final.png",
                        height: 16,
                        width: 16,
                      ),
                      Expanded(
                        child: Text(
                          widget.newTripDetailsInfo!.dropOffAddress.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // Center(child: ElevatedButton(onPressed: ()async{
                  //   print(widget.newTripDetailsInfo!.pickUpLatLng!);
                  //   print(widget.newTripDetailsInfo!.dropOffLatLng!);
                  //   // await obtainDirectionAndDrawRoute(widget.newTripDetailsInfo!.pickUpLatLng!, widget.newTripDetailsInfo!.dropOffLatLng!);
                  // }, child:   Text("ARRIVED"))  ,)

                  ARRIVE_END_ON(context),
                ],
              ),
            ),
          ))
    ]));
  }

  Center ARRIVE_END_ON(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          //arrived button
          if (statusOfTrip == "accepted") {
            setState(() {
              buttonTitleText = "START TRIP";
              buttonColor = Colors.green;
            });

            statusOfTrip = "arrived";

            FirebaseDatabase.instance
                .ref()
                .child("tripRequests")
                .child(widget.newTripDetailsInfo!.tripID!)
                .child("status")
                .set("arrived");

            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (BuildContext context) => LoadingDialog(
                      messageText: 'Please wait...',
                    ));
            // markersSet.clear();
            // polylineSet.clear();
            //setState(() async{
            print(
              "pickup" + widget.newTripDetailsInfo!.pickUpLatLng!.toString(),
            );
            print("dropoff" +
                widget.newTripDetailsInfo!.dropOffLatLng!.toString());
            await obtainDirectionAndDrawRoute(
              widget.newTripDetailsInfo!.pickUpLatLng!,
              widget.newTripDetailsInfo!.dropOffLatLng!,
            );
            //  });

            getLiveLocationUpdatesOfDriver();

            Navigator.pop(context);
          }
          //start trip button
          else if (statusOfTrip == "arrived") {
            setState(() {
              buttonTitleText = "END TRIP";
              buttonColor = Colors.amber;
            });

            statusOfTrip = "ontrip";

            FirebaseDatabase.instance
                .ref()
                .child("tripRequests")
                .child(widget.newTripDetailsInfo!.tripID!)
                .child("status")
                .set("ontrip");
          }
          //end trip button
          else if (statusOfTrip == "ontrip") {
            //end the trip
            endTripNow();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
        ),
        child: Text(
          buttonTitleText,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
