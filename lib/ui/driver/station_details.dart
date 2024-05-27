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
    // Split the location string into components
    List<String> locationComponents = station.location.split(',');

    // Ensure the location string has the expected number of components
    String roadCode = locationComponents.length > 0 ? locationComponents[0] : 'N/A';
    String location = locationComponents.length > 1 ? locationComponents[1] : 'N/A';
    String distanceTo = locationComponents.length > 2 ? locationComponents[2] : 'N/A';
    String distanceFrom = locationComponents.length > 3 ? locationComponents[3] : 'N/A';

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
            _buildLocationTile('Road Code', roadCode),
            _buildLocationTile('Location', location),
            _buildLocationTile('Distance To', distanceTo),
            _buildLocationTile('Distance From', distanceFrom),
            SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                launchMap(station.gpsLink);
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                onPrimary: Colors.white,
                textStyle: TextStyle(fontSize: 16.0),
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              ),
              child: Text('Open Maps'),
            ),
            SizedBox(height: 20.0),
            _buildSectionTitle('Fuel Availability:'),
            _buildFuelAvailability(),
            SizedBox(height: 20.0),
            _buildSectionTitle('Services Offered:'),
            _buildServicesOffered(),
            SizedBox(height: 20.0),
            _buildSectionTitle('Fuel Prices:'),
            _buildFuelPrices(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
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
            '$title: ',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16.0),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTile(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
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
      child: Text(
        text,
        style: TextStyle(fontSize: 16.0),
      ),
    );
  }

  Widget _buildPriceRow(String fuelType, double price) {
    return _buildTile('$fuelType: $price');
  }

  Widget _buildServiceRow(String serviceName, bool isAvailable) {
    return _buildTile('$serviceName: ${isAvailable ? 'Available' : 'Not Available'}');
  }

  Widget _buildFuelAvailability() {
    return FutureBuilder(
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
            _buildFuelAvailabilityTile('Petrol', services.isPetrolAvailable),
            _buildFuelAvailabilityTile('Diesel', services.isDieselAvailable),
          ],
        );
      },
    );
  }

  Widget _buildFuelAvailabilityTile(String fuelType, bool isAvailable) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
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
            '$fuelType: ',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          Text(
            isAvailable ? 'Available' : 'Not Available',
            style: TextStyle(fontSize: 16.0),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesOffered() {
    return FutureBuilder(
      future: FirestoreService().getStationServices(station.id),
      builder: (context, serviceSnapshot) {
        if (serviceSnapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (serviceSnapshot.hasError) {
          return Text('Error loading services');
        }
        var services = serviceSnapshot.data as StationServices;

        // Concatenate all available services into one string
        String allServices = services.availableServices.join(', ');

        return _buildTile(allServices);
      },
    );
  }

  Widget _buildFuelPrices() {
    return FutureBuilder(
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
    );
  }
}