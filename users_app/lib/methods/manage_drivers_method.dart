import 'package:users_app/models/online_nearby_drivers.dart';

class ManageDriversMethods{
  static List<OnlineNearbyDrivers> nearbyOnlineDriversList=[];

  static removeDriverFromList(String driverID)
  {
    int index=nearbyOnlineDriversList.indexWhere((driver) =>driver.uidDriver==driverID);
    if(nearbyOnlineDriversList.length >0)
    {
      nearbyOnlineDriversList.removeAt(index);
    }
  }
  static void updateOnlineNearbyDriversLocation(OnlineNearbyDrivers nearbyDriversInformation)
  {
    int index=nearbyOnlineDriversList.indexWhere((driver) =>driver.uidDriver==nearbyDriversInformation.uidDriver);

    nearbyOnlineDriversList[index].latDriver=nearbyDriversInformation.latDriver;
    nearbyOnlineDriversList[index].lngDriver=nearbyDriversInformation.lngDriver;
  }

}