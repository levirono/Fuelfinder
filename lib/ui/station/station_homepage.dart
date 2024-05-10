import 'package:flutter/material.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuel_station.dart';
// import 'package:ff_main/models/station_services.dart';
import 'station_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StationHomePage extends StatefulWidget {
  @override
  _StationHomePageState createState() => _StationHomePageState();
}

class _StationHomePageState extends State<StationHomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();



  late String _stationId;
  late StationServices _stationServices = StationServices(
    isPetrolAvailable: false,
    isDieselAvailable: false,
    petrolPrice: 0.0,
    dieselPrice: 0.0,
    isOpen: false,
    availableServices: [],
  );

  Future<String?> _stationNameFuture = Future.value('Station Name');
Future<List<String>> _servicesOfferedFuture = Future.value([]);

@override
void initState() {
  super.initState();
  _fetchStationData();
}

Future<void> _fetchStationData() async {
  User? currentUser = await _authService.getCurrentUser();
  if (currentUser != null) {
    FuelStation? station = await _firestoreService.getStationByOwnerId(currentUser.uid);
    if (station != null) {
      setState(() {
        _stationId = station.id;
        _stationNameFuture = Future.value(station.name); // Correct initialization
        _servicesOfferedFuture = _firestoreService.getServicesOffered(_stationId);// Correct initialization

          _fetchStationServices();
        });
      }
    }
  }


  Future<void> _fetchStationServices() async {
    try {
      _stationServices = await _firestoreService.getStationServices(_stationId);
      print('Fetched station services: $_stationServices'); // Debug print
      setState(() {}); // Refresh the UI after fetching services
    } catch (e) {
      // Handle error fetching station services
      print('Error fetching station services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String?>(
          future: _stationNameFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            } else {
              if (snapshot.hasError || snapshot.data == null) {
                return Text('Error');
              } else {
                final stationName = snapshot.data!;
                return Text(
                  'FUELFINDER - $stationName',
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.green[100],
                  ),
                );
              }
            }
          },
        ),
        backgroundColor: Colors.purple,
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
                color: Colors.purple,
              ),
              child: Text(
                'Station Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StationProfile()),
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
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50.0,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            SizedBox(height: 40.0,),
                  Container(
                    padding: EdgeInsets.all(25.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiffffffffffffffffffffffffffhjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjdppiottttttttttttttttthscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.green,
                      ),
                    ),
                  ),

            SizedBox(height: 20.0),
            SwitchListTile(
              title: Text(
                'Petrol Available',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),

              value: _stationServices.isPetrolAvailable,
              onChanged: (newValue) {
                setState(() {
                  _stationServices.isPetrolAvailable = newValue;
                  _updateStationServices();
                });
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Petrol Price'),
              keyboardType: TextInputType.number,
              initialValue: _stationServices.petrolPrice.toString(),
              onChanged: (value) {
                setState(() {
                  _stationServices.petrolPrice = double.parse(value);
                  _updateStationServices();
                });
              },
            ),
            SizedBox(height: 20.0),
            SwitchListTile(
              title: Text('Diesel Available',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _stationServices.isDieselAvailable,
              onChanged: (newValue) {
                setState(() {
                  _stationServices.isDieselAvailable = newValue;
                  _updateStationServices();
                });
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Diesel Price'),
              keyboardType: TextInputType.number,
              initialValue: _stationServices.dieselPrice.toString(),
              onChanged: (value) {
                setState(() {
                  _stationServices.dieselPrice = double.parse(value);
                  _updateStationServices();
                });
              },
            ),
            SizedBox(height: 20.0),
            SwitchListTile(
              title: Text('Station Open',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _stationServices.isOpen,
              onChanged: (newValue) {
                setState(() {
                  _stationServices.isOpen = newValue;
                  _updateStationServices();
                });
              },
            ),
            SizedBox(height: 20.0),
            FutureBuilder<List<String>>(
  future: _servicesOfferedFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    } else {
      if (snapshot.hasError || snapshot.data == null) {
        return Text('Error fetching services offered.');
      } else {
        final servicesOffered = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Services:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10.0),
            // Display checkbox list based on servicesOffered
            ...servicesOffered.map((service) {
              bool isSelected = _stationServices.availableServices.contains(service);
              return CheckboxListTile(
                title: Text(service),
                value: isSelected,
                onChanged: (newValue) {
                  setState(() {
                    if (newValue != null) {
                      if (newValue) {
                        _stationServices.availableServices.add(service);
                      } else {
                        _stationServices.availableServices.remove(service);
                      }
                      _updateStationServices();
                    }
                  });
                },
              );
            }).toList(),
          ],
        );
      }
    }
  },
),

            
            // Inside the build method of StationHomePage widget


          ],
        ),
      ),
    );
  }

  List<Widget> _buildServiceCheckboxes() {
    return _stationServices.availableServices.map((service) {
      return CheckboxListTile(
        title: Text(service),
        value: true, // Implement logic to track and update service availability
        onChanged: (newValue) {
          // Implement logic to update service availability
        },
      );
    }).toList();
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

  Future<void> _updateStationServices() async {
    try {
      await _firestoreService.updateStationServices(_stationId, _stationServices);
    } catch (e) {
      // Handle error updating station services
      print('Error updating station services: $e');
    }
  }
}
