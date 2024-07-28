import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/ui/driver/station_details.dart';
import 'package:ff_main/models/fuelfinder.dart';

class AllFuelStationsPage extends StatefulWidget {
  const AllFuelStationsPage({Key? key}) : super(key: key);

  @override
  AllFuelStationsPageState createState() => AllFuelStationsPageState();
}

class AllFuelStationsPageState extends State<AllFuelStationsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String searchQuery = '';
  List<FuelStation> stations = [];
  Map<String, double> stationDistances = {};
  bool isLoading = true;
  bool isCalculatingDistances = false;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final stream = _firestoreService.streamVerifiedStations();
      stream.listen((data) {
        setState(() {
          stations = data;
          isLoading = false;
        });
        _calculateDistances();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _calculateDistances() async {
    setState(() {
      isCalculatingDistances = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      for (var station in stations) {
        LatLng? stationLocation = _parseCoordinates(station.gpsLink);
        if (stationLocation != null) {
          double distance = await calculateRoadDistance(currentLocation, stationLocation);
          setState(() {
            stationDistances[station.id] = distance;
          });
        }
      }
    } catch (e) {
      print('Error calculating distances: $e');
    } finally {
      setState(() {
        isCalculatingDistances = false;
      });
    }
  }

  Future<double> calculateRoadDistance(LatLng start, LatLng end) async {
    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?access_token=${dotenv.env['MAPBOX_ACCESS_TOKEN']}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final distance = data['routes'][0]['distance'];
      return distance / 1000; // Converting to kilometers
    } else {
      throw Exception('Failed to load directions');
    }
  }

  bool isOpenAllDay(FuelStation station) {
    return station.isOpenAllDay;
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
      return 'Not Updated';
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
        title: const Text(
          'All Fuel Stations',
          style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        backgroundColor: Colors.green[100],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStationsList() {
    List<FuelStation> filteredStations = stations;
    if (searchQuery.isNotEmpty) {
      filteredStations = stations
          .where((station) =>
              station.location.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return ListView.builder(
      itemCount: filteredStations.length,
      itemBuilder: (context, index) {
        return _buildStationTile(filteredStations[index]);
      },
    );
  }

  Widget _buildStationTile(FuelStation station) {
    return StreamBuilder<StationServices>(
      stream: _firestoreService.streamStationServices(station.id),
      builder: (context, serviceSnapshot) {
        if (serviceSnapshot.connectionState == ConnectionState.waiting) {
          return _buildListTile(station.name, 'Loading services...', Colors.grey);
        }
        if (serviceSnapshot.hasError || !serviceSnapshot.hasData) {
          return _buildListTile(station.name, 'Services unavailable', Colors.grey);
        }
        final StationServices services = serviceSnapshot.data!;
        String stationStatus = services.isOpen 
            ? getStationStatus(station) 
            : 'Temporarily Closed';

        String distanceText = stationDistances.containsKey(station.id)
            ? 'Distance: ${stationDistances[station.id]!.toStringAsFixed(2)} km'
            : isCalculatingDistances ? 'Calculating distance...' : 'Distance unavailable';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FuelStationDetailsPage(station: station),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_gas_station),
                        const SizedBox(width: 8.0),
                        Text(
                          station.name,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.location_on),
                        const SizedBox(width: 8.0),
                        Text(
                          distanceText,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle,
                                color: services.isPetrolAvailable
                                    ? Colors.green
                                    : Colors.red),
                            const SizedBox(width: 4.0),
                            const Text('Petrol'),
                            const SizedBox(width: 16.0),
                            Icon(Icons.circle,
                                color: services.isDieselAvailable
                                    ? Colors.green
                                    : Colors.red),
                            const SizedBox(width: 4.0),
                            const Text('Diesel'),
                          ],
                        ),
                        Text(
                          stationStatus,
                          style: TextStyle(
                              color: stationStatus == 'Open' ||
                                      stationStatus == 'Open 24/7'
                                  ? Colors.green
                                  : stationStatus == 'Closing soon' ||
                                          stationStatus == 'Opening soon'
                                      ? Colors.orange
                                      : Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
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
                                    ? 'Operation Hours: ${station.operationStartTime} - ${station.operationEndTime}'
                                    : 'not updated',
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTile(String title, String subtitle, Color backgroundColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
        color: backgroundColor,
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
      ),
    );
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
          // print('Error parsing coordinates: $e');
        }
      }
    }
    return null;
  }
}