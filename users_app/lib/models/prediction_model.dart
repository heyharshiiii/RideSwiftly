class PredictionModel
{
  String? place_id;
  String? name;
  String? lat;
  String? lon;
 // String? osm_id;
  PredictionModel({
    this.place_id,
    this.name,
    this.lat,
    this.lon
  });

  PredictionModel.fromJson(Map<String,dynamic> json)
  {
    place_id=json["place_id"].toString();
    name=json["display_name"].toString();
    lat=json["lat"].toString();
    lon=json["lon"].toString();
  }
}