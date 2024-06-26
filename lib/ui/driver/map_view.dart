import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';

class MapView extends StatelessWidget {
  MapView({Key? key}) : super(key: key);

  final FirestoreService _firestoreService = FirestoreService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FUELFINDER',
          style: TextStyle(fontSize: 20.0, color: Colors.green),
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
            return Center(child: Text('Error fetching location: ${snapshot.error}'));
          }

          LatLng currentLocation = snapshot.data ?? const LatLng(51.505, -0.09);

          return StreamBuilder<List<FuelStation>>(
            stream: _firestoreService.streamStationsWithServices(),
            builder: (context, stationSnapshot) {
              if (stationSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (stationSnapshot.hasError) {
                return Center(child: Text('Error fetching stations: ${stationSnapshot.error}'));
              }

              List<FuelStation> stations = stationSnapshot.data ?? [];
              // Filter stations to show only verified ones
              List<FuelStation> verifiedStations = stations.where((station) => station.isVerified).toList();

              return Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 4,
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
                              title: Text('${suggestion.latitude}, ${suggestion.longitude}'),
                            );
                          },
                          onSelected: (Location suggestion) {
                            final LatLng newLocation = LatLng(suggestion.latitude, suggestion.longitude);
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
                          'View nearby verified stations to refuel',
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
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://api.mapbox.com/styles/v1/genixl/clvl3kmme011v01o0gh95hmt4/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiZ2VuaXhsIiwiYSI6ImNsdmtvc2RiNTI2M3Aya256NnB3ajJlczIifQ.7abytkEEOSsAdSFy3QXWQg',
                              additionalOptions: const {
                                'accessToken':
                                    'pk.eyJ1IjoiZ2VuaXhsIiwiYSI6ImNsdmtvc2RiNTI2M3Aya256NnB3ajJlczIifQ.7abytkEEOSsAdSFy3QXWQg',
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
                                    child: const Column(
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
                                ),...verifiedStations.map((station) {
  LatLng? coordinates = _parseCoordinates(station.gpsLink);

  if (coordinates != null) {
    return Marker(
      width: 80,
      height: 80.0,
      point: coordinates,
      child:GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10.0),
                      StreamBuilder<StationServices>(
                        stream: _firestoreService.streamStationServices(station.id),
                        builder: (context, serviceSnapshot) {
                          if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (serviceSnapshot.hasError) {
                            return const Text('Error loading services');
                          }
                          if (!serviceSnapshot.hasData) {
                            return const Text('Services unavailable');
                          }
                          StationServices services = serviceSnapshot.data!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.circle, color: services.isPetrolAvailable ? Colors.green : Colors.red),
                                  const SizedBox(width: 5.0),
                                  Text('Petrol: ${services.isPetrolAvailable ? 'Available' : 'Unavailable'}'),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Row(
                                children: [
                                  Icon(Icons.circle, color: services.isDieselAvailable ? Colors.green : Colors.red),
                                  const SizedBox(width: 5.0),
                                  Text('Diesel: ${services.isDieselAvailable ? 'Available' : 'Unavailable'}'),
                                ],
                              ),
                              const SizedBox(height: 5.0),
                              Text(
                                'Status: ${services.isOpen ? 'Open' : 'Closed'}',
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
            },
          );
        },
        child: Column(
          children: [
            const Icon(Icons.local_gas_station, color: Colors.blue, size: 40.0),
            const SizedBox(height: 2.0),
            Text(
              station.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  } else {
    return const Marker(
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
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
          final LatLng newLocation = LatLng(locations.first.latitude, locations.first.longitude);
          _mapController.move(newLocation, 13.0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No results found')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid address')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching for place: $e')));
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      return const LatLng(51.505, -0.09);
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

