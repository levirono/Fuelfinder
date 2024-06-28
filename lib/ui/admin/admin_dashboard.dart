import 'package:flutter/material.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/ui/admin/drivers.dart';
import 'package:ff_main/ui/admin/stations.dart';
import 'package:ff_main/ui/driver/fuel_efficiency_tips.dart';
import 'package:ff_main/utils/logout_confirmation.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final FirestoreService _firestoreService = FirestoreService();

  late Future<int> _stationCount;
  late Future<int> _driverCount;

  @override
  void initState() {
    super.initState();
    _stationCount = _firestoreService.getStationCount();
    _driverCount = _firestoreService.getDriverCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
              
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.0,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Monitor and Manage your stations and drivers adequately:',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),
            FutureBuilder<int>(
              future: _stationCount,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return _buildContainer(
                    'Stations',
                    snapshot.data.toString(),
                    Colors.black,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StationsPage()),
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 16.0),
            FutureBuilder<int>(
              future: _driverCount,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return _buildContainer(
                    'Drivers',
                    snapshot.data.toString(),
                    Colors.black,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DriversPage()),
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 16.0),
            _buildContainer(
              'Fuel Efficiency Tips',
              '',
              Colors.grey,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FuelEfficiencyTips()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainer(String title, String count, Color countColor, void Function() onTap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  TextSpan(
                    text: count.isNotEmpty ? ': $count' : '',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: countColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'View $title',
                style: const TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
