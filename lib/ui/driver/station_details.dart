import 'package:flutter/material.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:ff_main/services/firestore_service.dart';

class FuelStationDetailsPage extends StatelessWidget {
  final FuelStation station;

  FuelStationDetailsPage({required this.station});


  @override
  Widget build(BuildContext context) {
    List<String> locationComponents = station.location.split(',');

    String roadCode = locationComponents.length > 0 ? locationComponents[0].trim() : 'N/A';
    String location = locationComponents.length > 1 ? locationComponents[1].trim() : 'N/A';
    String distanceTo = locationComponents.length > 2 ? locationComponents[2].trim() : 'N/A';
    String distanceFrom = locationComponents.length > 3 ? locationComponents[3].trim() : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(station.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color:Colors.green[900]
        ),
        ),
        backgroundColor: Colors.green[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLocationTile('Location', location),
            _buildLocationTile('Road Code', roadCode),
            _buildLocationTile('Distance To', distanceTo),
            _buildLocationTile('Distance From', distanceFrom),
            SizedBox(height: 20.0),
            _buildSectionTitle('FUEL AVAILABILITY:'),
            _buildFuelAvailability(),
            SizedBox(height: 20.0),
            _buildSectionTitle('FUEL PRICES:'),
            _buildFuelPrices(),
            SizedBox(height: 20.0),
            _buildSectionTitle('SERVICES OFFERED:'),
            _buildServicesOffered(),
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
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 16.0),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
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

  Widget _buildFuelAvailability() {
    return FutureBuilder(
      future: FirestoreService().getStationServices(station.id),
      builder: (context, AsyncSnapshot<StationServices> serviceSnapshot) {
        if (serviceSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (serviceSnapshot.hasError || !serviceSnapshot.hasData) {
          return Text('Error loading services');
        }
        var services = serviceSnapshot.data!;

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
            style: TextStyle(
              fontSize: 16.0,
              color: isAvailable ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesOffered() {
    return FutureBuilder(
      future: FirestoreService().getStationServices(station.id),
      builder: (context, AsyncSnapshot<StationServices> serviceSnapshot) {
        if (serviceSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (serviceSnapshot.hasError || !serviceSnapshot.hasData) {
          return Text('Error loading services');
        }
        var services = serviceSnapshot.data!;

        // Concatenate all available services into one string
        String allServices = services.availableServices.join(', ');

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
            allServices,
            style: TextStyle(fontSize: 16.0),
          ),
        );
      },
    );
  }

  Widget _buildFuelPrices() {
    return FutureBuilder(
      future: FirestoreService().getStationServices(station.id),
      builder: (context, AsyncSnapshot<StationServices> serviceSnapshot) {
        if (serviceSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (serviceSnapshot.hasError || !serviceSnapshot.hasData) {
          return Text('Error loading services');
        }
        var services = serviceSnapshot.data!;

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

  Widget _buildPriceRow(String fuelType, double price) {
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
            '${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
