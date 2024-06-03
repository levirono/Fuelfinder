import 'dart:convert';
import 'dart:math';
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

class DriverHomePage extends StatefulWidget {
  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
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
  }

  Future<void> _checkDriverProfile() async {
    User? currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      Driver? existingDriver = await _firestoreService.getDriverByOwnerId(currentUser.uid);
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Complete Your Profile',
            style: TextStyle(fontSize: 20.0, color: Colors.green),
          ),
          content: Text('Please complete your driver profile to proceed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DriverProfile()),
                );
              },
              child: Text(
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
      setState(() {
        _isProfileLoaded = true;
      });
    });
  }

  Future<void> _showRandomFuelEfficiencyTip() async {
    if (isFirstTime) {
      List<FuelEfficiencyTip> tips = await _firestoreService.getFuelEfficiencyTips();
      if (tips.isNotEmpty) {
        FuelEfficiencyTip randomTip = tips[Random().nextInt(tips.length)];

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.green[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Colors.green, width: 2.0),
              ),
              title: Text(
                'Fuel Efficiency Tip',
                style: TextStyle(color: Colors.green[800]),
              ),
              content: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.green, width: 2.0),
                ),
                padding: EdgeInsets.all(16.0),
                child: Text(
                  randomTip.tip,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
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
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<double> calculateRoadDistance(LatLng start, LatLng end) async {
    final String url = 'https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?access_token=pk.eyJ1IjoiZ2VuaXhsIiwiYSI6ImNsdmtwZzVyNjB3bDUydnA3eGNrNHplN3QifQ.M5AHspWj4Wb19XqLD26Gtg';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract distance (in meters)
      final distance = data['routes'][0]['distance'];
      return distance / 1000; // Convert to kilometers
    } else {
      throw Exception('Failed to load directions');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isProfileLoaded || _currentLocation == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FUELFINDER',
          style: TextStyle(fontSize: 30.0, color: Colors.green),
        ),
        backgroundColor: Colors.green[100],
        actions: [
          IconButton(
            icon: Icon(Icons.logout,color:Colors.red,size:30.0),
            onPressed: () {
              _showLogoutConfirmationDialog(context);
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
              child: Text(
                'Application',
                style: TextStyle(color: Colors.green, fontSize: 24.0),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DriverProfile()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('Fuel Efficiency Tips'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FuelEfficiencyTips()),
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
            padding: EdgeInsets.all(16.0), // Adjust padding as needed
            decoration: BoxDecoration(
              color: Colors.grey[200], // Background color similar to list of stations
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(20.0),
                right: Radius.circular(20.0),
              ),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Driver! How is your journey?',
                  style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Find nearest fuel station to refill:',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        searchQuery = searchQuery.trim();
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  searchQuery = value;
                },
              ),
            ),
          ),
         Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  PermissionStatus locationStatus = await Permission.location.request();

                  if (locationStatus == PermissionStatus.granted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapView()),
                    );
                  }

                  if (locationStatus == PermissionStatus.denied) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('This permission is required to use maps')),
                    );
                  }

                  if (locationStatus == PermissionStatus.permanentlyDenied) {
                    openAppSettings();
                  }
                },
                icon: Icon(Icons.map, color: Colors.white),
                label: Text(
                  'View Stations on Map',
                  style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),


          SizedBox(height: 16.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Fuel Stations:',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FuelStation>>(
              stream: _firestoreService.streamStations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No stations found'));
                }
                List<FuelStation> stations = snapshot.data!;
                if (searchQuery.isNotEmpty) {
                  stations = stations.where((station) => station.location.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                }
                return ListView.builder(
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    FuelStation station = stations[index];
                    return _buildStationTile(station);
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
  return FutureBuilder(
    future: Future.wait([
      _firestoreService.getStationServices(station.id),
      calculateRoadDistance(
        _currentLocation!,
        _parseCoordinates(station.gpsLink) ?? LatLng(0.0, 0.0),
      )
    ]),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildListTile(station.name, 'Loading...', Colors.grey);
      }
      if (snapshot.hasError) {
        return _buildListTile(station.name, 'Data uavailable', Colors.grey);
      }
      final data = snapshot.data as List<dynamic>;
      final StationServices services = data[0];
      final double distance = data[1];

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
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(20.0),
              right: Radius.circular(20.0),
            ),
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(20.0),
                  right: Radius.circular(20.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_gas_station),
                      SizedBox(width: 8.0),
                      Text(
                        station.name,
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios), // Added arrow icon for navigation
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(Icons.location_on),
                      SizedBox(width: 8.0),
                      Text(
                        'Distance: ${distance.toStringAsFixed(2)} km',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: services.isPetrolAvailable ? Colors.green : Colors.red),
                          SizedBox(width: 4.0),
                          Text('Petrol'),
                          SizedBox(width: 16.0),
                          Icon(Icons.circle, color: services.isDieselAvailable ? Colors.green : Colors.red),
                          SizedBox(width: 4.0),
                          Text('Diesel'),
                        ],
                      ),
                      Text(
                        services.isOpen ? 'Open' : 'Closed',
                        style: TextStyle(color: services.isOpen ? Colors.green : Colors.red),
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
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
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

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout Confirmation'),
          backgroundColor: Colors.green[100],
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red[400]),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _authService.logout();
                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }
}

