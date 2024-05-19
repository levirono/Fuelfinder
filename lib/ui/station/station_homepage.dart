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
          _stationNameFuture = Future.value(station.name);
          _servicesOfferedFuture = _firestoreService.getServicesOffered(_stationId);
          _fetchStationServices();
        });
      } else {
        // Station profile doesn't exist, show dialog to fill details
        _showStationProfileDialog();
      }
    }
  }

  Future<void> _fetchStationServices() async {
    try {
      _stationServices = await _firestoreService.getStationServices(_stationId);
      print('Fetched station services: $_stationServices');
      setState(() {});
    } catch (e) {
      print('Error fetching station services: $e');
    }
  }

  void _showStationProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Complete Your Station Profile'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please fill in your station details to proceed.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StationProfile()),
                ).then((value) {
                  // After filling the profile, re-fetch the station data
                  _fetchStationData();
                });
              },
            ),
          ],
        );
      },
    );
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
                    color: Colors.orange,
                  ),
                );
              }
            }
          },
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
                color: Colors.green[100],
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
            SizedBox(height: 40.0),
            Container(
              padding: EdgeInsets.all(25.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
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
              title: Text(
                'Diesel Available',
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
              title: Text(
                'Station Open',
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildServiceCheckboxes() {
    return _stationServices.availableServices.map((service) {
      return CheckboxListTile(
        title: Text(service),
        value: true,
        onChanged: (newValue) {},
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

  Future<void> _updateStationServices() async {
    try {
      await _firestoreService.updateStationServices(_stationId, _stationServices);
    } catch (e) {
      print('Error updating station services: $e');
    }
  }
}
