import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:users_app/appInfo/appInfo.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/methods/common_methods.dart';
import 'package:users_app/models/address_model.dart';
import 'package:users_app/models/prediction_model.dart';
import 'package:users_app/widgets/loading_dialog.dart';

class PredictionPlaceUI extends StatefulWidget
{
  PredictionModel? predictedPlaceData;

  PredictionPlaceUI({super.key, this.predictedPlaceData,});

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI>
{
  ///Place Details - Places API
  fetchClickedPlaceDetails(String placeID) async
  {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting details..."),
    );
    // print( "OSMMMMMMMMMMM"+widget.predictedPlaceData!.osm_id.toString());
    // print("PLACE IDDDDDDDDD"+widget.predictedPlaceData!.place_id.toString());
    // String urlPlaceDetailsAPI = "https://nominatim.openstreetmap.org/details.php?osmtype=N&osmid=${widget.predictedPlaceData!.osm_id}&placeid=${widget.predictedPlaceData!.place_id}&format=json";

    // var responseFromPlaceDetailsAPI = await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI);
    // print("RESPONSEEEEEEEEEE"+responseFromPlaceDetailsAPI);
    // Navigator.pop(context);

    // if(responseFromPlaceDetailsAPI == "error")
    // {
    //   return;
    // }
     
    }
  

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: ()
      {
         AddressModel dropOffLocation = AddressModel();

      dropOffLocation.placeName = widget.predictedPlaceData!.name;
      dropOffLocation.latitudePosition = widget.predictedPlaceData!.lat;
      dropOffLocation.longitudePosition =widget.predictedPlaceData!.lon;
      dropOffLocation.placeID = widget.predictedPlaceData!.place_id;
     // print(dropOffLocation);
      Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(dropOffLocation);
      Navigator.pop(context, dropOffLocation);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
      ),
      child: SizedBox(
        child: Column(
          children: [

            const SizedBox(height: 10,),

            Row(
              children: [

                const Icon(
                  Icons.share_location,
                  color: Colors.grey,
                ),

                const SizedBox(width: 13,),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [

                      Text(
                        widget.predictedPlaceData!.name.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      //   children: [
                      //     Text(
                      //   widget.predictedPlaceData!.lat.toString(),
                      //   overflow: TextOverflow.ellipsis,
                      //   style: const TextStyle(
                      //     fontSize: 10,
                      //     color: Colors.black87,
                      //   ),
                      // ),
                      
                      //  Text(
                      //   widget.predictedPlaceData!.lon.toString(),
                      //   overflow: TextOverflow.ellipsis,
                      //   style: const TextStyle(
                      //     fontSize: 10,
                      //     color: Colors.black87,
                      //   ),
                      // ),
                      //   ],
                      // )
                       

                    ],
                  ),
                ),

              ],
            ),

            const SizedBox(height: 10,),

          ],
        ),
      ),
    );
  }
}
