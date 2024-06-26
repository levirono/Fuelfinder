import 'dart:convert';
import 'dart:math';
import 'package:ff_main/ui/about.dart';
import 'package:ff_main/utils/carousel_item.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'driver_profile.dart';
import 'fuel_efficiency_tips.dart';
import 'package:ff_main/ui/driver/station_details.dart';
import 'map_view.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:ff_main/ui/driver/all_stations.dart';
import 'package:ff_main/utils/logout_confirmation.dart';


class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  DriverHomePageState createState() => DriverHomePageState();
}

class DriverHomePageState extends State<DriverHomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController(initialPage: 0);

  String searchQuery = '';
  bool isFirstTime = true;
  bool _isProfileLoaded = false;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _checkDriverProfile();
    _showRandomFuelEfficiencyTip();
    _getCurrentLocation();
    Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page!.round() + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> _checkDriverProfile() async {
    User? currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      Driver? existingDriver =
          await _firestoreService.getDriverByOwnerId(currentUser.uid);
      if (existingDriver == null) {
        _showDriverProfileDialog();
      } else {
        setState(() {
          _isProfileLoaded = true;
        });
      }
    }
  }

  void _showDriverProfileDialog() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Complete Your Profile',
                style: TextStyle(fontSize: 20.0, color: Colors.green),
              ),
              content:
                  const Text('Please complete your driver profile to proceed.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DriverProfile()),
                    );
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
              backgroundColor: Colors.green[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            );
          },
        ).then((value) {
          if (mounted) {
            setState(() {
              _isProfileLoaded = true;
            });
          }
        });
      }
    });
  }

  Future<void> _showRandomFuelEfficiencyTip() async {
    if (isFirstTime) {
      List<FuelEfficiencyTip> tips =
          await _firestoreService.getFuelEfficiencyTips();
      if (tips.isNotEmpty) {
        FuelEfficiencyTip randomTip = tips[Random().nextInt(tips.length)];

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Fuel Efficiency Tip',
                style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold),
              ),
              content: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.green, width: 2.0),
                ),
                child: Text(
                  randomTip.tip,
                  style: const TextStyle(fontSize: 18.0),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 12.0),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
      isFirstTime = false;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<double> calculateRoadDistance(LatLng start, LatLng end) async {
    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?access_token=pk.eyJ1IjoiZ2VuaXhsIiwiYSI6ImNsdmtwZzVyNjB3bDUydnA3eGNrNHplN3QifQ.M5AHspWj4Wb19XqLD26Gtg';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract distance
      final distance = data['routes'][0]['distance'];
      return distance / 1000; // Converting to kilometers
    } else {
      throw Exception('Failed to load directions');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isProfileLoaded || _currentLocation == null) {
      return const Scaffold(
          // body: Center(child: CircularProgressIndicator()),
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FUELFINDER',
          style: TextStyle(fontSize: 30.0, color: Colors.green),
        ),
        backgroundColor: Colors.green[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red, size: 30.0),
            onPressed: () {
              LogoutConfirmationDialog.show(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey[100]),
              child: const Text(
                'Application',
                style: TextStyle(color: Colors.green, fontSize: 24.0),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DriverProfile()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Fuel Efficiency Tips'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FuelEfficiencyTips()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const About()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20.0),
                right: Radius.circular(20.0),
              ),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20.0),
                SizedBox(
                  height: 300.0,
                  child: PageView(
                    controller: _pageController,
                    children: const [
                      CarouselItem(
                          imagePath:'assets/images/welcome1.png',
                          title:'FIND THE NEAREST FUEL STATION TO REFILL',
                          subtitle: 'always have a view of fuel stations to refill your car,save your time.'),
                      CarouselItem(
                          imagePath: 'assets/images/welcome2.png',
                          title:'COMPREHENSIVE MAP VIEW',
                          subtitle:'You can open map view to see the stations on the map'),
                      CarouselItem(
                          imagePath:'assets/images/welcome3.png',
                          title:'EFFICIENCY TIPS',
                          subtitle: 'You get fuel efficiency tips that will hep you save your fuel and time.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Search Route',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter road code or route',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            searchQuery = searchQuery.trim();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                PermissionStatus locationStatus =
                    await Permission.location.request();

                if (locationStatus == PermissionStatus.granted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapView()),
                  );
                }

                if (locationStatus == PermissionStatus.denied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This permission is required to use maps'),
                    ),
                  );
                }

                if (locationStatus == PermissionStatus.permanentlyDenied) {
                  openAppSettings();
                }
              },
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text(
                'View Stations on Map',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Stations near me:',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FuelStation>>(
              stream: _firestoreService.streamVerifiedStations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No stations found'));
                }
                List<FuelStation> stations = snapshot.data!;
                if (searchQuery.isNotEmpty) {
                  stations = stations
                      .where((station) => station.location
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                      .toList();
                }

                return FutureBuilder<List<FuelStation>>(
                  future: _sortStationsByDistance(stations),
                  builder: (context, sortedSnapshot) {
                    if (sortedSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!sortedSnapshot.hasData ||
                        sortedSnapshot.data!.isEmpty) {
                      return const Center(child: Text('No stations found'));
                    }
                    List<FuelStation> sortedStations = sortedSnapshot.data!;

                    return ListView.builder(
                      itemCount: sortedStations.length + 1,
                      itemBuilder: (context, index) {
                        if (index < sortedStations.length) {
                          ///changes right now
                          return _buildStationTile(sortedStations[index]);
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          AllFuelStationsPage()),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward,
                                  color: Colors.white),
                              label: const Text(
                                'View All Stations',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationTile(FuelStation station) {
    return FutureBuilder<double>(
      future: calculateRoadDistance(
        _currentLocation!,
        _parseCoordinates(station.gpsLink) ?? const LatLng(0.0, 0.0),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListTile(station.name, 'Loading...', Colors.grey);
        }
        if (snapshot.hasError) {
          return _buildListTile(station.name, 'Data unavailable', Colors.grey);
        }
        final double distance = snapshot.data!;

        return StreamBuilder<StationServices>(
          stream: _firestoreService.streamStationServices(station.id),
          builder: (context, serviceSnapshot) {
            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
              return _buildListTile(
                  station.name, 'Loading services...', Colors.grey);
            }
            if (serviceSnapshot.hasError || !serviceSnapshot.hasData) {
              return _buildListTile(
                  station.name, 'Services unavailable', Colors.grey);
            }
            final StationServices services = serviceSnapshot.data!;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FuelStationDetailsPage(station: station),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20.0),
                    right: Radius.circular(20.0),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20.0),
                        right: Radius.circular(20.0),
                      ),
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
                              'Distance: ${distance.toStringAsFixed(2)} km',
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
                              services.isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                  color: services.isOpen
                                      ? Colors.green
                                      : Colors.red),
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
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
          print('Error parsing coordinates: $e');
        }
      }
    }
    return null;
  }

  Future<List<FuelStation>> _sortStationsByDistance(
      List<FuelStation> stations) async {
    List<MapEntry<FuelStation, double>> stationsWithDistances =
        await Future.wait(stations.map((station) async {
      double distance = await calculateRoadDistance(
        _currentLocation!,
        _parseCoordinates(station.gpsLink) ?? const LatLng(0.0, 0.0),
      );
      return MapEntry(station, distance);
    }));

    stationsWithDistances =
        stationsWithDistances.where((entry) => entry.value <= 20).toList();

    stationsWithDistances.sort((a, b) => a.value.compareTo(b.value));
    return stationsWithDistances.map((e) => e.key).toList();
  }
}