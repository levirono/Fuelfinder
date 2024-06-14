import 'package:ff_main/ui/driver/driver_homepage.dart';
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
  final _phoneNumberController = TextEditingController(text: '+254');
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateNumberController = TextEditingController();
  final _driverLicenseController = TextEditingController();

  final _authService = AuthService();

  Driver? _existingDriver;
  bool _editMode = true;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    User? currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      Driver? existingDriver = await _firestoreService.getDriverByOwnerId(currentUser.uid);
      setState(() {
        _existingDriver = existingDriver;
        if (_existingDriver != null) {
          _populateFormFields();
        }
        _editMode = _existingDriver == null;
      });
    }
  }

  void _populateFormFields() {
    _nameController.text = _existingDriver!.name;
    _phoneNumberController.text = _existingDriver!.phoneNumber;
    _vehicleModelController.text = _existingDriver!.vehicleModel;
    _vehiclePlateNumberController.text = _existingDriver!.vehiclePlateNumber;
    _driverLicenseController.text = _existingDriver!.driverLicense;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MY PROFILE'),
        backgroundColor: Colors.green[100],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormField('Driver Name', _nameController),
                _buildFormField('Phone Number', _phoneNumberController, prefixText: '+254'),
                _buildFormField('Vehicle Model', _vehicleModelController),
                _buildFormField('Vehicle Plate Number', _vehiclePlateNumberController, hintText: 'e.g., KDJ299F'),
                _buildFormField('Driver License', _driverLicenseController, hintText: 'e.g., A12345678'),
                SizedBox(height: 20.0),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {String? prefixText, String? hintText}) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              prefixText: prefixText,
              hintText: hintText,
              border: OutlineInputBorder(),
            ),
            readOnly: !_editMode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _editMode ? _saveProfile : _toggleEditMode,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            // onbackgroundColor: Colors.white,
          ),
          child: Text(_editMode ? 'Save' : 'Edit'),
        ),
      ],
    );
  }

  void _toggleEditMode() {
    setState(() {
      _editMode = true;
    });
  }

   Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You need to be logged in to save your profile.')));
        return;
      }

      String driverId = _existingDriver?.id ?? Uuid().v4();

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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DriverHomePage()),
      );
    }
  }

}
