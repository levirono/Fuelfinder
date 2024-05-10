import 'package:flutter/material.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FuelStationDetailsPage extends StatelessWidget {
  final FuelStation station;

  FuelStationDetailsPage({required this.station});
  void launchMap(String gpsLink) async {
    if (await canLaunch(gpsLink)) {
      await launch(gpsLink);
    } else {
      throw 'Could not launch $gpsLink';
    }
  }

  @override
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
        backgroundColor: Colors.green[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location: ${station.location}',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.0),
           ElevatedButton(
              onPressed: () {
                launchMap(station.gpsLink);
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.green, // Button color
                onPrimary: Colors.white, // Text color
                textStyle: TextStyle(fontSize: 16.0), // Text style
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0), // Button padding
              ),
              child: Text('Open Maps'),
            ),
            SizedBox(height: 20.0),
            Text(
              'Fuel Availability:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.0),
            FutureBuilder(
              future: FirestoreService().getStationServices(station.id),
              builder: (context, serviceSnapshot) {
                if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (serviceSnapshot.hasError) {
                  return Text('Error loading services');
                }
                var services = serviceSnapshot.data as StationServices;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceRow('Petrol', services.isPetrolAvailable),
                    _buildServiceRow('Diesel', services.isDieselAvailable),
                  ],
                );
              },
            ),
            SizedBox(height: 20.0),
            Text(
              'Services Offered:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.0),
            FutureBuilder(
              future: FirestoreService().getStationServices(station.id),
              builder: (context, serviceSnapshot) {
                if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (serviceSnapshot.hasError) {
                  return Text('Error loading services');
                }
                var services = serviceSnapshot.data as StationServices;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: services.availableServices
                      .map((serviceName) => _buildServiceRow(serviceName, true))
                      .toList(),
                );
              },
            ),
            SizedBox(height: 20.0),
            Text(
              'Fuel Prices:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.0),
            FutureBuilder(
              future: FirestoreService().getStationServices(station.id),
              builder: (context, serviceSnapshot) {
                if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (serviceSnapshot.hasError) {
                  return Text('Error loading services');
                }
                var services = serviceSnapshot.data as StationServices;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceRow('Petrol Price', services.petrolPrice),
                    _buildPriceRow('Diesel Price', services.dieselPrice),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPriceRow(String fuelType, double price) {
    return Row(
      children: [
        Text(
          '$fuelType: ',
          style: TextStyle(fontSize: 16.0),
        ),
        Text(
          price.toString(),
          style: TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }

  Widget _buildServiceRow(String serviceName, bool isAvailable) {
    return Row(
      children: [
        Icon(Icons.circle, color: isAvailable ? Colors.green : Colors.red),
        SizedBox(width: 8),
        Text(
          '$serviceName: ${isAvailable ? 'Available' : 'Not Available'}',
          style: TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }

  
}
