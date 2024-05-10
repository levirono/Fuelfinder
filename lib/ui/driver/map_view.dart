import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:ff_main/services/firestore_service.dart';

class MapView extends StatelessWidget {
  MapView({Key? key}) : super(key: key);

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FUELFINDER'),
      ),
      body: FutureBuilder<LatLng>(
        future: _getCurrentLocation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching location: ${snapshot.error}'));
          }

          LatLng currentLocation = snapshot.data ?? LatLng(51.505, -0.09); // Default to London

          return StreamBuilder<List<FuelStation>>(
            stream: _firestoreService.streamStationsWithServices(),
            builder: (context, stationSnapshot) {
              if (stationSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (stationSnapshot.hasError) {
                return Center(child: Text('Error fetching stations: ${stationSnapshot.error}'));
              }

              List<FuelStation> stations = stationSnapshot.data ?? [];

              return FlutterMap(
                options: MapOptions(
                  center: currentLocation,
                  zoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/genixl/clvl3kmme011v01o0gh95hmt4/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiZ2VuaXhsIiwiYSI6ImNsdmtvc2RiNTI2M3Aya256NnB3ajJlczIifQ.7abytkEEOSsAdSFy3QXWQg',
                    additionalOptions: {
                      'access token': 'pk.eyJ1IjoiZ2VuaXhsIiwiYSI6ImNsdmtvc2RiNTI2M3Aya256NnB3ajJlczIifQ.7abytkEEOSsAdSFy3QXWQg',
                      'id': 'mapbox.mapbox-streets-v8',
                    },
                  ),
                  MarkerLayer(
  markers: [
    Marker(
      width: 80.0,
      height: 80.0,
      point: currentLocation,
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, color: Colors.red, size: 40.0),
            SizedBox(height: 5.0),
            Text(
              'Me Driver',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
    ...stations.map((station) {
      LatLng? coordinates = _parseCoordinates(station.gpsLink);

      if (coordinates != null) {
        return Marker(
          width: 150.0,
          height: 150.0,
          point: coordinates,
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_gas_station, color: Colors.blue, size: 40.0),
                SizedBox(height: 2.0),
                Text(
                  '${station.name}',
                  overflow: TextOverflow.fade,
                  maxLines: 3,
                    style: TextStyle(fontSize: 12.0),

                ),
                SizedBox(height: 5.0),
                FutureBuilder<StationServices>(
                  future: _firestoreService.getStationServices(station.id),
                  builder: (context, serviceSnapshot) {
                    if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (serviceSnapshot.hasError) {
                      return Text('Error loading services');
                    }
                    StationServices services = serviceSnapshot.data!;

                    return Row(
                      children: [
                        SizedBox(height:5.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, color: services.isPetrolAvailable ? Colors.green : Colors.red),
                            SizedBox(width: 5.0),
                            Text(
                              services.isPetrolAvailable ? 'P' : 'P',
                              style: TextStyle(color: services.isPetrolAvailable ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, color: services.isDieselAvailable ? Colors.green : Colors.red),
                            SizedBox(width: 5.0),
                            Text(
                              services.isDieselAvailable ? 'D' : 'D',
                              style: TextStyle(color: services.isDieselAvailable ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.0),
                        Text(
                          services.isOpen ? ' -Open' : ' -Closed',
                          style: TextStyle(color: services.isOpen ? Colors.green : Colors.red),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        return Marker(
          width: 0.0,
          height: 0.0,
          point: LatLng(0.0, 0.0),
          child: SizedBox.shrink(),
        );
      }
    }).toList(),
  ],
),

                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      return LatLng(51.505, -0.09);
    }
  }

  LatLng? _parseCoordinates(String? gpsLink) {
    if (gpsLink != null && gpsLink.isNotEmpty) {
      var coordinates = gpsLink.split(',');
      if (coordinates.length == 2) {
        try {
          double latitude = double.parse(coordinates[0].trim());
          double longitude = double.parse(coordinates[1].trim());
          return LatLng(latitude, longitude);
        } catch (e) {
          print('Error parsing coordinates: $e');
        }
      }
    }
    return null;
  }
}
