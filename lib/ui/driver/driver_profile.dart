import 'package:flutter/material.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:uuid/uuid.dart';
import 'package:ff_main/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverProfile extends StatefulWidget {
  @override
  _DriverProfileState createState() => _DriverProfileState();
}

class _DriverProfileState extends State<DriverProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateNumberController = TextEditingController();
  final _driverLicenseController = TextEditingController();

  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Profile'),
        backgroundColor: Colors.blue[200],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormField('Name', _nameController),
                _buildFormField('Phone Number', _phoneNumberController),
                _buildFormField('Vehicle Model', _vehicleModelController),
                _buildFormField('Vehicle Plate Number', _vehiclePlateNumberController),
                _buildFormField('Driver License', _driverLicenseController),
                SizedBox(height: 20.0),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String labelText, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $labelText';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter $labelText',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return ElevatedButton(
      onPressed: _saveProfile,
      child: Text('Save'),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return;
      }

      String driverId = Uuid().v4();

      Driver driver = Driver(
        id: driverId,
        name: _nameController.text,
        phoneNumber: _phoneNumberController.text,
        vehicleModel: _vehicleModelController.text,
        vehiclePlateNumber: _vehiclePlateNumberController.text,
        driverLicense: _driverLicenseController.text,
      );

      await _firestoreService.addOrUpdateDriver(driver, currentUser.uid);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Driver profile saved')));
    }
  }
}
