import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class PickMyCoordinate extends StatefulWidget {
  const PickMyCoordinate({super.key});

  @override
  PickMyCoordinateState createState() => PickMyCoordinateState();
}

class PickMyCoordinateState extends State<PickMyCoordinate> {
  LatLng? _selectedCoordinate;
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FUELFINDER',
          style: TextStyle(
              fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        backgroundColor: Colors.green[100],
      ),
      body: FutureBuilder<LatLng>(
        future: _getCurrentLocation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error fetching location: ${snapshot.error}'));
          }

          LatLng currentLocation = snapshot.data ?? const LatLng(0.001, 35.09);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TypeAheadField<Location>(
                      suggestionsCallback: (pattern) async {
                        if (pattern.isNotEmpty) {
                          return await locationFromAddress(pattern);
                        } else {
                          return [];
                        }
                      },
                      itemBuilder: (context, Location suggestion) {
                        return ListTile(
                          title: Text(
                              '${suggestion.latitude}, ${suggestion.longitude}'),
                        );
                      },
                      onSelected: (Location suggestion) {
                        final LatLng newLocation =
                            LatLng(suggestion.latitude, suggestion.longitude);
                        _mapController.move(newLocation, 13.0);
                      },
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: _searchController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search for a place',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            fillColor: Colors.grey[200],
                            filled: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                if (_searchController.text.isNotEmpty) {
                                  _searchPlace(_searchController.text, context);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Zoom in and tap your location to pick your coordinates',
                      style: TextStyle(fontSize: 20, color: Colors.green),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_in, size: 30.0),
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_out, size: 30.0),
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
                  padding: const EdgeInsets.all(10),
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
                              'https://api.mapbox.com/styles/v1/genixl/clvl3kmme011v01o0gh95hmt4/tiles/256/{z}/{x}/{y}@2x?access_token=${dotenv.env['MAPBOX_ACCESS_TOKEN']}',
                          additionalOptions: {
                            'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN']!,
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

  Future<void> _searchPlace(String place, BuildContext context) async {
    try {
      if (place.isNotEmpty) {
        List<Location> locations = await locationFromAddress(place);
        if (locations.isNotEmpty) {
          final LatLng newLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
          _mapController.move(newLocation, 13.0);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No results found')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid address')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching for place: $e')));
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      return const LatLng(51.505, -0.09);
    }
  }

  void _handleTap(LatLng tappedPoint) {
    setState(() {
      _selectedCoordinate = tappedPoint;
    });

// Copy coordinates to clipboard using platform channel
    String coordinatesText =
        '${_selectedCoordinate!.latitude}, ${_selectedCoordinate!.longitude}';

    Clipboard.setData(ClipboardData(text: coordinatesText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates copied to clipboard')),
      );
// Navigate back to the station profile page after copying coordinates
      Navigator.pop(context, coordinatesText);
    }).catchError((error) {
      print('Error copying to clipboard: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to copy coordinates')),
      );
    });

    print(
        'Selected Coordinates: ${_selectedCoordinate!.latitude}, ${_selectedCoordinate!.longitude}');
  }
}
