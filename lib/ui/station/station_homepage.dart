import 'package:ff_main/ui/about.dart';
import 'package:flutter/material.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'station_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:ff_main/utils/logout_confirmation.dart';
import 'package:ff_main/utils/carousel_item.dart';



class StationHomePage extends StatefulWidget {
  const StationHomePage({super.key});

  @override
  StationHomePageState createState() => StationHomePageState();
}

class StationHomePageState extends State<StationHomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController(initialPage: 0);

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
  bool _isVerified = false; //verification status
  
  Stream<bool> _verificationStatusStream() {
    return _firestoreService.getVerificationStatusStream(_stationId);
  }

  @override
  void initState() {
    super.initState();
    _fetchStationData();
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


  Future<void> _fetchStationData() async {
    if (!mounted) return;

    User? currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      FuelStation? station = await _firestoreService.getStationByOwnerId(currentUser.uid);
      if (station != null) {
        setState(() {
          _stationId = station.id;
          _isVerified = station.isVerified;
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
          title: const Text(
            'Complete Your Station Profile',
            style: TextStyle(fontSize: 20.0, color: Colors.green),
          ),
          content: const SingleChildScrollView(
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
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StationProfile()),
                ).then((value) {
                  _fetchStationData();
                });
              },
            ),
          ],
          backgroundColor: Colors.green[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
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
              return const Text('Loading...');
            } else {
              if (snapshot.hasError || snapshot.data == null) {
                return const Text('Error');
              } else {
                final stationName = snapshot.data!;
                return Text(
                  stationName,
                  style: const TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 1, 33, 3),
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
              decoration: BoxDecoration(
                color: Colors.green[100],
              ),
              child: const Text(
                'Station Profile',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24.0,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StationProfile()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About'),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green[200]!],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20.0),
              const Text(
                'Welcome!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
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
              const SizedBox(height: 20.0),
              _buildVerificationStatus(),
              const SizedBox(height: 20.0),
              _buildStatusTile('Station Status', _stationServices.isOpen),
              const SizedBox(height: 20.0),
              _buildFuelTile('Petrol', _stationServices.isPetrolAvailable, _stationServices.petrolPrice),
              const SizedBox(height: 20.0),
              _buildFuelTile('Diesel', _stationServices.isDieselAvailable, _stationServices.dieselPrice),
              const SizedBox(height: 20.0),
              FutureBuilder<List<String>>(
                future: _servicesOfferedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else {
                    if (snapshot.hasError || snapshot.data == null) {
                      return const Text('Error fetching services offered.');
                    } else {
                      final servicesOffered = snapshot.data!;
                      return Container(
                        padding: const EdgeInsets.all(16.0),
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
                            const SizedBox(height: 10.0),
                            Column(
                              children: servicesOffered.map((service) {
                                bool isSelected = _stationServices.availableServices.contains(service);
                                return CheckboxListTile(
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: Text(service),
                                  value: isSelected,
                                  onChanged: _isVerified
                                      ? (newValue) {
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
                                        }
                                      : null,
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


  Widget _buildVerificationStatus() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _isVerified ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: _isVerified ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
            spreadRadius: 4,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Verification Status:',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: _isVerified ? Colors.green[900] : Colors.red[900],
            ),
          ),
          Text(
            _isVerified ? 'Verified' : 'Not Verified',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: _isVerified ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(String title, bool isOpen) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    margin: const EdgeInsets.symmetric(vertical: 10.0),
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
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8.0),
        GestureDetector(
          onTap: _isVerified
              ? () {
                  setState(() {
                    _stationServices.isOpen = !_stationServices.isOpen;
                    _updateStationServices();
                  });
                }
              : () {
                  _showVerificationPopup();
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Center(
              child: Text(
                isOpen ? 'OPEN tap to close' : 'ClOSED tap to open',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFuelTile(String fuelType, bool isAvailable, double price) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    margin: const EdgeInsets.symmetric(vertical: 10.0),
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
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8.0),
        GestureDetector(
          onTap: _isVerified
              ? () {
                  setState(() {
                    if (fuelType == 'Petrol') {
                      _stationServices.isPetrolAvailable = !_stationServices.isPetrolAvailable;
                    } else if (fuelType == 'Diesel') {
                      _stationServices.isDieselAvailable = !_stationServices.isDieselAvailable;
                    }
                    _updateStationServices();
                  });
                }
              : () {
                  _showVerificationPopup();
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Center(
              child: Text(
                isAvailable ? 'Available ..tap change' : 'not available ..tap to chage',
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'price:',
              style: TextStyle(fontSize: 16.0, color: Colors.black),
            ),
            const SizedBox(width: 8.0),
            SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter price',
                ),
                keyboardType: TextInputType.number,
                initialValue: price.toString(),
                onChanged: _isVerified
                    ? (value) {
                        setState(() {
                          if (fuelType == 'Petrol') {
                            _stationServices.petrolPrice = double.parse(value);
                          } else if (fuelType == 'Diesel') {
                            _stationServices.dieselPrice = double.parse(value);
                          }
                          _updateStationServices();
                        });
                      }
                    : (value) {
                        _showVerificationPopup();
                      },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void _showVerificationPopup() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.green[100],
        title: const Text('Verification Required'),
        content: const Text('You need to be verified to perform this action.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK',
            style: TextStyle(
              color: Colors.green,
              fontSize:15.0,
            ),
            
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