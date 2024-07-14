import 'package:ff_main/ui/driver/driver_homepage.dart';
import 'package:flutter/material.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuelfinder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:ff_main/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverProfile extends StatefulWidget {
  const DriverProfile({super.key});

  @override
  DriverProfileState createState() => DriverProfileState();
}

class DriverProfileState extends State<DriverProfile> {
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
        title: const Text('MY PROFILE',
        style: TextStyle(fontSize:30.0,fontWeight: FontWeight.bold,color: Colors.green),

        ),
        
        backgroundColor: Colors.green[100],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
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
                const SizedBox(height: 20.0),
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
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              prefixText: prefixText,
              hintText: hintText,
              border: const OutlineInputBorder(),
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
    if (_existingDriver == null || _editMode) {
      return ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          minimumSize: const Size(double.infinity, 40.0),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: Colors.white),
            SizedBox(width: 8.0),
            Text(
              'Save Station Profile',
              style: TextStyle(
                fontSize: 16.0,
                color:Colors.white,
                ),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () => setState(() => _editMode = true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          minimumSize: const Size(double.infinity, 40.0),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8.0),
            Text(
              'Edit Profile',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      );
    }
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
        Fluttertoast.showToast(
          msg: "Login failed!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.yellow,
          textColor: Colors.white,
          fontSize: 16.0
        );
        return;
      }

      String driverId = _existingDriver?.id ?? const Uuid().v4();

      Driver driver = Driver(
        id: driverId,
        name: _nameController.text,
        phoneNumber: _phoneNumberController.text,
        vehicleModel: _vehicleModelController.text,
        vehiclePlateNumber: _vehiclePlateNumberController.text,
        driverLicense: _driverLicenseController.text,
      );

      await _firestoreService.addOrUpdateDriver(driver, currentUser.uid);
      Fluttertoast.showToast(
          msg: "Driver profile saved",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0
        );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DriverHomePage()),
      );
    }
  }

}
