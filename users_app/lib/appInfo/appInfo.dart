import 'package:flutter/material.dart';
import 'package:users_app/models/address_model.dart';

class AppInfo extends ChangeNotifier
{
  AddressModel? pickUpLocation;
  AddressModel? dropOffLocation;

  void updatePickUpLocation(AddressModel pickUpModel)
  {
    pickUpLocation=pickUpModel;
    notifyListeners();
  }

  void updateDropOffLocation(AddressModel droppOffModel)
  {
    dropOffLocation=droppOffModel;
    notifyListeners();
    
  }
}