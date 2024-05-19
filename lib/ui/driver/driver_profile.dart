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

  Driver? _existingDriver;
  bool _editMode = false;

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
        title: Text('Driver Profile'),
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

  Widget _buildFormField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      readOnly: !_editMode,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _editMode ? _saveProfile : _toggleEditMode,
          child: Text(_editMode ? 'Save' : 'Edit'),
        ),
        if (_existingDriver != null)
          ElevatedButton(
            onPressed: _deleteProfile,
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(
              primary: Colors.red,
            ),
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
    
    Navigator.pop(context);

    _loadDriverProfile();
  }
}


  Future<void> _deleteProfile() async {
    User? currentUser = await _authService.getCurrentUser();
    if (currentUser != null && _existingDriver != null) {
      await _firestoreService.deleteDriver(_existingDriver!.id, currentUser.uid);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Driver profile deleted')));
      _clearFormFields();
      setState(() {
        _existingDriver = null;
        _editMode = false;
      });
    }
  }

  void _clearFormFields() {
    _nameController.clear();
    _phoneNumberController.clear();
    _vehicleModelController.clear();
    _vehiclePlateNumberController.clear();
    _driverLicenseController.clear();
  }
}
