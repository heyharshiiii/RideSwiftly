import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:users_app/appInfo/appInfo.dart';
import 'package:users_app/global/global.dart';
import 'package:http/http.dart' as http;
import 'package:users_app/models/address_model.dart';
import 'package:users_app/models/direction_details.dart';
class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();
    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      // if(!context.mounted) return;
      displaySnackBar(
          "It looks like you're offline. Please check your internet connection and try again",
          context);
      print(connectionResult);
    }
  }

  displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

 static sendRequestToAPI(String apiUrl) async {
  var url = Uri.parse(apiUrl);
      var responseFromAPI = await http.get(url);
  try{
    if(responseFromAPI.statusCode==200)
    {
      var dataDecoded= jsonDecode(responseFromAPI.body);
      return dataDecoded;
    }
    else
    {
      print("no status error");
      return "error";
    }
  }
  catch(errorMsg)
  {
    print("error");
    return "error";
  }
 }



//REVERSE GEOCODING
  static Future<String> convertCoordinatesToHumanReadable(
      Position position, BuildContext context) async {
        String humanReadableAddress="";
    String apiGeoCodingUrl = "https://us1.locationiq.com/v1/reverse?key=${locIQApiKey}&lat=${position.latitude}&lon=${position.longitude}&format=json";
    var reponseFromAPI = await sendRequestToAPI(apiGeoCodingUrl);
    if(reponseFromAPI!="error")
    {
      humanReadableAddress=reponseFromAPI["display_name"];
      print( "HUMAN READABLE ADDRESSS:"+humanReadableAddress);
      AddressModel model=AddressModel();
      model.humanReadableAddress=humanReadableAddress;
      model.latitudePosition=position.latitude.toString();
      model.longitudePosition=position.longitude.toString();

      Provider.of<AppInfo>(context,listen:false).updatePickUpLocation(model);

    }
    else
    {
      print("retry");
    }
    return humanReadableAddress;
  }

///DIRECTIONS API
static Future<DirectionDetails?> getDirectionDetailsFromAPI(double srclong,double srclat,String? destlong,String? destlat) async
{
  String urlDirectionAPI="https://us1.locationiq.com/v1/directions/driving/${srclong},${srclat};${destlong},${destlat}?key=pk.de81bff2492636d69ea6e6c60ea5f12f&overview=simplified&geometries=polyline";
  var responseFromDiretionsAPI=await sendRequestToAPI(urlDirectionAPI);
  if(responseFromDiretionsAPI=="error")
  {
    return null;
  }
  DirectionDetails detailsModel=DirectionDetails();
  detailsModel.distanceValueDigits= responseFromDiretionsAPI["routes"][0]["distance"];
  detailsModel.durationValueDigits= responseFromDiretionsAPI["routes"][0]["duration"];
  detailsModel.encodedPoints=responseFromDiretionsAPI["routes"][0]["geometry"];

  return detailsModel;
}

//calculate FARE AMOUNT

calculateFareAmount(DirectionDetails directionDetails)
{
  double distancePerKmAmount=0.4; //for each km
  double durationPerMinAmount=0.3; //for each min
  double baseFaremount=2; //for the company

  double totaldistanceFareAmount=(directionDetails.distanceValueDigits!/1000)*distancePerKmAmount;
  double totaldurationFareAmount=(directionDetails.durationValueDigits!/60)*durationPerMinAmount;

  double totalAmount=baseFaremount+totaldurationFareAmount+totaldistanceFareAmount;
  return totalAmount.toStringAsFixed(2);

}

}

