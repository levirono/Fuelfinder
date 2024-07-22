import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ff_main/models/fuelfinder.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  MapViewState createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(13.0);

  final FirestoreService _firestoreService = FirestoreService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Stream<Position>? _positionStream;
  LatLng _currentPosition = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupPositionStream();
    _mapController.mapEventStream.listen(_onMapEvent);
  }

  void _onMapEvent(MapEvent mapEvent) {
    if (mapEvent is MapEventMove) {
      _zoomNotifier.value = _mapController.camera.zoom;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition, _mapController.camera.zoom);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _setupPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings);
    _positionStream?.listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  (bool, double) _getMarkerVisibilityAndSize(double zoom) {
    if (zoom < 10) {
      return (false, 0);
    } else if (zoom < 12) {
      return (true, 20);
    } else if (zoom < 14) {
      return (true, 40);
    } else {
      return (true, 80);
    }
  }

  DateTime parseTime(String time) {
    final now = DateTime.now();
    try {
      time = time.trim();
      List<String> components = time.split(' ');
      if (components.length != 2) {
        throw const FormatException('Invalid time format');
      }

      String timeComponent = components[0];
      String amPm = components[1].toUpperCase();

      List<String> timeParts = timeComponent.split(':');
      if (timeParts.length != 2) {
        throw const FormatException('Invalid time format');
      }

      int hours = int.parse(timeParts[0]);
      int minutes = int.parse(timeParts[1]);

      if (amPm == 'PM' && hours != 12) {
        hours += 12;
      } else if (amPm == 'AM' && hours == 12) {
        hours = 0;
      }

      return DateTime(now.year, now.month, now.day, hours, minutes);
    } catch (e) {
      print('Error parsing time: $e');
      return now;
    }
  }

  String getStationStatus(FuelStation station) {
    if (station.isOpenAllDay) return 'Open 24/7';

    final now = DateTime.now();
    DateTime openTime;
    DateTime closeTime;

    try {
      openTime = parseTime(station.operationStartTime);
      closeTime = parseTime(station.operationEndTime);
    } catch (e) {
      print('Error parsing station times: $e');
      return 'Hours unavailable';
    }

    if (now.isAfter(openTime) && now.isBefore(closeTime)) {
      final minutesToClose = closeTime.difference(now).inMinutes;
      if (minutesToClose <= 60) {
        return 'Closing soon';
      }
      return 'Open';
    } else {
      final minutesToOpen = openTime.difference(now).inMinutes;
      if (minutesToOpen <= 60 && minutesToOpen > 0) {
        return 'Opening soon';
      }
      return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FUELFINDER',
            style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.green)),
        backgroundColor: Colors.green[100],
      ),
      body: Column(
        children: [
          _buildSearchContainer(),
          Expanded(
            child: _buildMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContainer() {
    return Container(
      height: MediaQuery.of(context).size.height / 4,
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          const Text(
            'View nearby verified stations to refuel',
            style: TextStyle(fontSize: 20, color: Colors.green),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _buildZoomButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TypeAheadField<Location>(
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
    );
  }

  Widget _buildZoomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_in, size: 30.0),
          onPressed: () {
            double newZoom = _mapController.camera.zoom + 1;
            _mapController.move(_mapController.camera.center, newZoom);
            _zoomNotifier.value = newZoom;
          },
        ),
        IconButton(
          icon: const Icon(Icons.zoom_out, size: 30.0),
          onPressed: () {
            double newZoom = _mapController.camera.zoom - 1;
            _mapController.move(_mapController.camera.center, newZoom);
            _zoomNotifier.value = newZoom;
          },
        ),
      ],
    );
  }

  Widget _buildMap() {
    return StreamBuilder<List<FuelStation>>(
      stream: _firestoreService.streamStationsWithServices(),
      builder: (context, stationSnapshot) {
        if (stationSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (stationSnapshot.hasError) {
          return Center(child: Text('Error: ${stationSnapshot.error}'));
        }
        List<FuelStation> stations = stationSnapshot.data ?? [];
        List<FuelStation> verifiedStations = stations.where((station) => station.isVerified).toList();

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentPosition,
            zoom: 13.0,
            onMapEvent: _onMapEvent,
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
            ValueListenableBuilder<double>(
              valueListenable: _zoomNotifier,
              builder: (context, zoom, child) {
                return MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _currentPosition,
                      child: _buildUserMarker(),
                    ),
                    ...verifiedStations.map((station) => _buildStationMarker(station, zoom)).toList(),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserMarker() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_car, color: Colors.redAccent, size: 20.0),
        SizedBox(height: 5.0),
      ],
    );
  }

  Marker _buildStationMarker(FuelStation station, double zoom) {
    LatLng? coordinates = _parseCoordinates(station.gpsLink);
    if (coordinates == null) {
      return Marker(width: 0, height: 0, point: const LatLng(0, 0), child: Container());
    }

    var (isVisible, size) = _getMarkerVisibilityAndSize(zoom);

    if (!isVisible) {
      return Marker(width: 0, height: 0, point: coordinates, child: Container());
    }

    return Marker(
      width: size,
      height: size,
      point: coordinates,
      child: GestureDetector(
        onTap: () => _showStationDialog(station),
        child: Column(
          children: [
            Icon(Icons.local_gas_station, color: Colors.blue, size: size * 0.5),
            if (size >= 40) ...[
              const SizedBox(height: 2.0),
              Text(
                station.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: size * 0.15),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStationDialog(FuelStation station) {
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
                    String stationStatus = services.isOpen 
                        ? getStationStatus(station) 
                        : 'Temporarily Closed';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle,
                                color: services.isPetrolAvailable ? Colors.green : Colors.red),
                            const SizedBox(width: 5.0),
                            Text('Petrol: ${services.isPetrolAvailable ? 'Available' : 'Unavailable'}'),
                          ],
                        ),
                        const SizedBox(height: 5.0),
                        Row(
                          children: [
                            Icon(Icons.circle,
                                color: services.isDieselAvailable ? Colors.green : Colors.red),
                            const SizedBox(width: 5.0),
                            Text('Diesel: ${services.isDieselAvailable ? 'Available' : 'Unavailable'}'),
                          ],
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          'Status: $stationStatus',
                          style: TextStyle(
                              color: stationStatus == 'Open' || stationStatus == 'Open 24/7'
                                  ? Colors.green
                                  : stationStatus == 'Closing soon'
                                      ? Colors.orange
                                      : Colors.red),
                        ),
                        const SizedBox(height: 5.0),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16.0),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                station.isOpenAllDay
                                    ? 'Open 24/7'
                                    : station.operationStartTime.isNotEmpty &&
                                            station.operationEndTime.isNotEmpty
                                        ? 'Hours: ${station.operationStartTime} - ${station.operationEndTime}'
                                        : 'Hours not available',
                                style: const TextStyle(fontSize: 14.0),
                              ),
                            ),
                          ],
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
  }

  LatLng? _parseCoordinates(String gpsLink) {
    try {
      var coords = gpsLink.split(',');
      if (coords.length == 2) {
        double latitude = double.parse(coords[0]);
        double longitude = double.parse(coords[1]);
        return LatLng(latitude, longitude);
      }
    } catch (e) {
      print('Error parsing coordinates: $e');
    }
    return null;
  }

  Future<void> _searchPlace(String query, BuildContext context) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        LatLng newLocation =
            LatLng(locations.first.latitude, locations.first.longitude);
        _mapController.move(newLocation, 13.0);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for place: $e')),
      );
    }
  }

  @override
  void dispose() {
    _zoomNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }
}