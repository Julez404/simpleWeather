import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(MaterialApp(
    title: "Weather App",
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  var temperature;
  var description;
  var currently;
  var humidity;
  var windSpeed;
  var long;
  var lat;
  var location;

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position? currentPosition;
    currentPosition = await Geolocator.getLastKnownPosition();

    if (currentPosition == null) {
      Future.error("Failed by timeout");
      throw TimeoutException("Failed to get Position");
    }

    return currentPosition;
  }

  Future UpdateLocation() async {
    Position position = await determinePosition();

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print(placemarks[0]);
      placemarks[0] != null ? location = placemarks[0].locality : "Unknown";
    } catch (err) {
      location = "Failed to detect";
    }
  }

  Future GetWeather() async {
    Position position;
    try {
      position = await determinePosition();
    } catch (err) {
      AlertDialog(title: Text("GetPosition() timed out\n" + err.toString()));
      return;
    }
    String? apiKey = dotenv.env['OPEN_WEATHER_API_KEY'];
    apiKey == null ? apiKey = "" : "";

    http.Response response = await http.get(Uri(
        scheme: 'http',
        host: 'api.openweathermap.org',
        path: '/data/2.5/weather/',
        queryParameters: {
          'lat': position.latitude.toString(),
          'lon': position.longitude.toString(),
          'units': 'metric',
          'appid': apiKey
        }));

    var result = jsonDecode(response.body);

    setState(() {
      this.long = result['coord']['lon'];
      this.lat = result['coord']['lat'];
      this.temperature = result['main']['temp'];
      this.description = result['weather'][0]['description'];
      this.windSpeed = result['wind']['speed'];
      this.humidity = result['main']['humidity'];
    });
  }

  @override
  void initState() {
    super.initState();
    GetWeather();
    UpdateLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: MediaQuery.of(context).size.height / 3,
            width: MediaQuery.of(context).size.width,
            color: Color.fromARGB(255, 80, 175, 3),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      location != null
                          ? "Wetter in " + location.toString()
                          : "Unknonw Position",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    temperature != null
                        ? temperature.toString() + "\u00B0"
                        : "Loading",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      description != null ? description.toString() : "Loading",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: ListView(children: <Widget>[
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.thermometerHalf),
                  title: Text("Temperatur"),
                  trailing: Text(temperature != null
                      ? temperature.toString() + "\u00B0"
                      : "Loading"),
                ),
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.percent),
                  title: Text("Humidity"),
                  trailing: Text(humidity != null
                      ? humidity.toString() + " %"
                      : "Loading"),
                ),
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.cloud),
                  title: Text("Weather"),
                  trailing: Text(
                      description != null ? description.toString() : "Loading"),
                ),
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.wind),
                  title: Text("Wind Speed"),
                  trailing: Text(windSpeed != null
                      ? windSpeed.toString() + " km/h"
                      : "Loading"),
                ),
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.globe),
                  title: Text("Longitude"),
                  trailing: Text(
                      long != null ? long.toString() + "\u00B0" : "Loading"),
                ),
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.globe),
                  title: Text("Latitude"),
                  trailing:
                      Text(lat != null ? lat.toString() + "\u00B0" : "Loading"),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
