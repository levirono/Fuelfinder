import 'package:flutter/material.dart';
import 'package:ff_main/models/fuelfinder.dart';
import 'package:ff_main/services/firestore_service.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  DriversPageState createState() => DriversPageState();
}

class DriversPageState extends State<DriversPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DRIVERS',
        style: TextStyle(fontSize:30.0,fontWeight: FontWeight.bold,color: Colors.green),
        ),
        backgroundColor: Colors.green[100],
        
      ),
      body: StreamBuilder<List<Driver>>(
        stream: _firestoreService.streamDrivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No drivers available'));
          } else {
            final drivers = snapshot.data!;
            return ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return _buildDriverTile(driver);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDriverTile(Driver driver) {
    return GestureDetector(
      onTap: () {
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
                    Expanded(
                      child: Text(
                        driver.name,
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteDriver(driver.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text('Phone: ${driver.phoneNumber}'),
                Text('Vehicle: ${driver.vehicleModel}'),
                Text('Plate: ${driver.vehiclePlateNumber}'),
                Text('License: ${driver.driverLicense}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteDriver(String driverId) {
    _firestoreService.deleteDriver(driverId);
  }
}
