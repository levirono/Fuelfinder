import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class PickMyCoordinate extends StatefulWidget {
  @override
  _PickMyCoordinateState createState() => _PickMyCoordinateState();
}

class _PickMyCoordinateState extends State<PickMyCoordinate> {
  LatLng? _selectedCoordinate;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

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

          LatLng currentLocation = snapshot.data ?? LatLng(0.001, 35.09); // Default to a location

          return Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height / 4,
                padding: EdgeInsets.all(10),
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Zoom in and tap your place to pick your coordinates',
                      style: TextStyle(fontSize: 20,
                      color: Colors.green
                      ),
                      textAlign: TextAlign.center,
                      
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.zoom_in,
                          size: 30.0,
                          ),
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.zoom_out,
                          size: 30.0,
                          ),
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: currentLocation,
                        zoom: 13.0,
                        onTap: (TapPosition tapPosition, LatLng latLng) {
                          _handleTap(latLng);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://api.mapbox.com/styles/v1/genixl/clvl3kmme011v01o0gh95hmt4/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiZ2VuaXhsIiwiYSI6ImNsdmtvc2RiNTI2M3Aya256NnB3ajJlczIifQ.7abytkEEOSsAdSFy3QXWQg',
                          additionalOptions: {
                            'accessToken': 'pk.eyJ1IjoiZ2VuaXhsIiwiYSI6ImNsdmtvc2RiNTI2M3Aya256NnB3ajJlczIifQ.7abytkEEOSsAdSFy3QXWQg',
                            'id': 'mapbox.mapbox-streets-v8',
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  void _handleTap(LatLng tappedPoint) {
    setState(() {
      _selectedCoordinate = tappedPoint;
    });

    // Copy coordinates to clipboard using platform channel
    String coordinatesText = '${_selectedCoordinate!.latitude}, ${_selectedCoordinate!.longitude}';
  
    Clipboard.setData(ClipboardData(text: coordinatesText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coordinates copied to clipboard')),
      );
    }).catchError((error) {
      print('Error copying to clipboard: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy coordinates')),
      );
    });

    print('Selected Coordinates: ${_selectedCoordinate!.latitude}, ${_selectedCoordinate!.longitude}');
  }
}
