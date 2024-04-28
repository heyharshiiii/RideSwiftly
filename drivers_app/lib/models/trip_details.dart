import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDetails
{
  String? tripID;

  LatLng? pickUpLatLng;
  String? pickUpAddress;

  LatLng? dropOffLatLng;
  String? dropOffAddress;

  String? userName;
  String? userPhone;

  TripDetails({
    this.tripID,
    this.dropOffAddress,
    this.dropOffLatLng,
    this.pickUpAddress,
    this.pickUpLatLng,
    this.userName,
    this.userPhone
  });
}