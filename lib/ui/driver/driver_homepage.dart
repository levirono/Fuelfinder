import 'package:ff_main/ui/driver/fuel_efficiency_tips.dart';
import 'package:ff_main/ui/driver/station_details.dart';
import 'package:flutter/material.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'driver_profile.dart';
import 'package:ff_main/ui/driver/map_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
class DriverHomePage extends StatefulWidget {
  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  String searchQuery = '';
  bool isFirstTime = true;


void initState() {
    super.initState();
    _showRandomFuelEfficiencyTip();
  }
Future<void> _showRandomFuelEfficiencyTip() async {
    if (isFirstTime) {
      // Get a random fuel efficiency tip from Firestore
      List<FuelEfficiencyTip> tips = await _firestoreService.getFuelEfficiencyTips();
      if (tips.isNotEmpty) {
        FuelEfficiencyTip randomTip = tips[Random().nextInt(tips.length)];

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                backgroundColor: Colors.green[100], // Set background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // Set rounded corners
                  side: BorderSide(color: Colors.green, width: 2.0), // Set border
                ),
                title: Text('Fuel Efficiency Tip',
                style: TextStyle(
                    color: Colors.green[800],
                  ),
                ),
                content: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0), // Set rounded corners
                    border: Border.all(color: Colors.green, width: 2.0), // Set border
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
                    Navigator.of(context).pop(); // Close dialog
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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FUELFINDER',
          style: TextStyle(
            fontSize: 20.0,
            color: Colors.green,
          ),
        ),
        backgroundColor: Colors.green[100],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: Text(
                'Aplication',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24.0,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to driver profile page
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
                // Navigate to driver profile page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FuelEfficiencyTips()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green[200]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome, Driver! How is your journey?',
                style: TextStyle(
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Find nearest fuel station to refill:',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: 
            // ),
            
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Route',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Container(
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
                      ],
                    ),
                  ),

                  ElevatedButton(
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
  child: Text(
    'Map View',
    style: TextStyle(
      color: Colors.white,
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
    ),
  ),
),




            Padding(
            padding: EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fuel Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('available', style: TextStyle(color: Colors.green)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Not Available', style: TextStyle(color: Colors.red)),
                  ],
                ),
                SizedBox(height: 8),
                
              ],
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
            // Filter stations that match the search query
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
      ),
    );
  }

  Widget _buildStationTile(FuelStation station) {
  return FutureBuilder(
    future: _firestoreService.getStationServices(station.id),
    builder: (context, serviceSnapshot) {
      if (serviceSnapshot.connectionState == ConnectionState.waiting) {
        return _buildListTile(station.name, 'Loading...', Colors.grey);
      }
      if (serviceSnapshot.hasError) {
        return _buildListTile(station.name, 'Error loading services', Colors.grey);
      }
      StationServices services = serviceSnapshot.data as StationServices;

      Color nameColor = Colors.amber; // Golden color for station name

      return Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
          color: Colors.grey[200],
        ),
        child: ListTile(
          leading: Icon(Icons.local_gas_station),
          title: Text(
            station.name,
            style: TextStyle(color: nameColor, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, color: services.isPetrolAvailable ? Colors.green : Colors.red),
                  SizedBox(width: 20),
                  Text('Petrol'),
                  SizedBox(width: 20),
                  Icon(Icons.circle, color: services.isDieselAvailable ? Colors.green : Colors.red),
                  SizedBox(width: 20),
                  Text('Diesel'),
                  SizedBox(width: 20),
                  Text(services.isOpen ? 'Open' : 'Closed'),

                ],
              ),
              SizedBox(height: 8),
              Text('GPS Link: ${station.gpsLink}'),
              Text(
              'Location: ${station.location}',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.0),
              Text('Operation Hours: ${station.operationHours}'),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,MaterialPageRoute(builder:(context)=>FuelStationDetailsPage(station: station),
              ),
            );
          },
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





  // Function to show logout confirmation dialog
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
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel',
              style: TextStyle(
                color:Colors.red[400]
              ),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Call AuthService to logout
                await _authService.logout();
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Logout',
              style: TextStyle(
                color: Colors.green
              ),),
            ),
          ],
        );
      },
    );
  }
}
