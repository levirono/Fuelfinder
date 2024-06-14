import 'package:flutter/material.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuel_station.dart';
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
    if (!mounted) return;

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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Complete Your Station Profile',
            style: TextStyle(fontSize: 20.0, color: Colors.green),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Please fill in your station details to proceed.',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(color: Colors.green), // Green text for button
              ),
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
          backgroundColor: Colors.green[100], // Green 100 background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Rounded corners
          ),
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
                  stationName,
                  style: TextStyle(
                    fontSize: 24.0,
                    color: Colors.green,
                  ),
                );
              }
            }
          },
        ),
        backgroundColor: Colors.green[100],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red, size: 30.0),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20.0),
              Text(
                'Welcome to Fuel Finder!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 20.0),
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Text('Logo and description image'),
                ),
              ),
              SizedBox(height: 20.0),
              _buildStatusTile('Station Status', _stationServices.isOpen, Colors.green),
              SizedBox(height: 20.0),
              _buildFuelTile('Petrol', _stationServices.isPetrolAvailable, _stationServices.petrolPrice, Colors.green),
              SizedBox(height: 20.0),
              _buildFuelTile('Diesel', _stationServices.isDieselAvailable, _stationServices.dieselPrice, Colors.red),
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
                      return Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              spreadRadius: 4,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Services:',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                            SizedBox(height: 10.0),
                            Column(
                              children: servicesOffered.map((service) {
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
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTile(String title, bool value, Color color) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelTile(String fuelType, bool isAvailable, double price, Color color) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fuelType,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAvailable ? 'Available' : 'Not Available',
                style: TextStyle(fontSize: 16.0, color: color),
              ),
              Switch(
                value: isAvailable,
                onChanged: (newValue) {
                  setState(() {
                    if (fuelType == 'Petrol') {
                      _stationServices.isPetrolAvailable = newValue;
                    } else if (fuelType == 'Diesel') {
                      _stationServices.isDieselAvailable = newValue;
                    }
                    _updateStationServices();
                  });
                },
              ),
            ],
          ),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Price',
            ),
            keyboardType: TextInputType.number,
            initialValue: price.toString(),
            onChanged: (value) {
              setState(() {
                if (fuelType == 'Petrol') {
                  _stationServices.petrolPrice = double.parse(value);
                } else if (fuelType == 'Diesel') {
                  _stationServices.dieselPrice = double.parse(value);
                }
                _updateStationServices();
              });
            },
          ),
        ],
      ),
    );
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
