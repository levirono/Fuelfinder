import 'package:flutter/material.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:uuid/uuid.dart';
import 'package:ff_main/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ff_main/ui/station/pick_my_coordinates.dart';
import 'package:ff_main/ui/station/station_homepage.dart';

class StationProfile extends StatefulWidget {
  const StationProfile({super.key});

  @override
  StationProfileState createState() => StationProfileState();
}

class StationProfileState extends State<StationProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _gpsLinkController = TextEditingController();
  final _servicesOfferedController = TextEditingController();
  final _operationHoursController = TextEditingController();
  final _roadCodeController = TextEditingController();
  final _routeController = TextEditingController();
  final _distanceToController = TextEditingController();
  final _distanceFromController = TextEditingController();

  final _authService = AuthService();

  FuelStation? _existingStation;
  bool _editMode = true;

  @override
  void initState() {
    super.initState();
    _loadStationProfile();
  }

  Future<void> _loadStationProfile() async {
    User? currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      FuelStation? existingStation =
          await _firestoreService.getStationByOwnerId(currentUser.uid);
      setState(() {
        _existingStation = existingStation;
        if (_existingStation != null) {
          _populateFormFields();
        }
      });
    }
  }

  void _populateFormFields() {
    _nameController.text = _existingStation!.name;
    _gpsLinkController.text = _existingStation!.gpsLink;
    _servicesOfferedController.text =
        _existingStation!.servicesOffered.join(', ');
    _operationHoursController.text = _existingStation!.operationHours;
    List<String> locationComponents = _existingStation!.location.split(',');
    if (locationComponents.length >= 4) {
      _roadCodeController.text = locationComponents[0].trim();
      _routeController.text = locationComponents[1].trim();
      _distanceToController.text = locationComponents[2].trim();
      _distanceFromController.text = locationComponents[3].trim();
    }
  }

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(color: Colors.green, fontSize: 30.0),
          ),
          if (_existingStation != null && _existingStation!.isVerified)
            const Icon(Icons.verified, color: Colors.blue),
        ],
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
              _buildFormField('Station Name', _nameController, mandatory: true),
              _buildFormField('GPS Link', _gpsLinkController, mandatory: true, example: 'latitude,longitude'),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _openPickMyCoordinateScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  minimumSize: const Size(double.infinity, 40.0),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.map, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Pick My Coordinates',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              _buildFormField('Road Code', _roadCodeController, mandatory: true, example: 'C39'),
              _buildFormField('Route', _routeController, mandatory: true, example: 'Eldoret-kapsabet'),
              _buildFormField('Distance To (km)', _distanceToController),
              _buildFormField('Distance From (km)', _distanceFromController),
              _buildFormField('Services Offered (comma-separated)', _servicesOfferedController),
              _buildFormField('Operation Hours', _operationHoursController),
              const SizedBox(height: 20.0),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildFormField(String labelText, TextEditingController controller,
      {bool mandatory = false, String example = ''}) {
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
          Row(
            children: [
              Text(
                labelText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (mandatory)
                const Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            enabled: _editMode,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: example.isNotEmpty ? 'e.g. $example' : null,
            ),
            validator: (value) {
              if (mandatory && (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_existingStation == null || _editMode) {
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = await _authService.getCurrentUser();

      if (currentUser == null) {
        return;
      }

      String stationId = _existingStation?.id ?? const Uuid().v4();

      String location = [
        _roadCodeController.text,
        _routeController.text,
        _distanceToController.text,
        _distanceFromController.text,
      ].join(',');

      FuelStation station = FuelStation(
        id: stationId,
        name: _nameController.text,
        location: location,
        gpsLink: _gpsLinkController.text,
        servicesOffered: _servicesOfferedController.text.split(','),
        operationHours: _operationHoursController.text,
      );

      await _firestoreService.addOrUpdateStation(station, currentUser.uid);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Station profile saved')));
      setState(() {
        _editMode = false;
        _loadStationProfile();
      });

      // Check if it's the first time saving the profile
      if (_existingStation == null) {
        // Navigate to StationHomePage after saving the profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StationHomePage()),
        );
      }
    }
  }

  void _openPickMyCoordinateScreen() async {
    final coordinatesText = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PickMyCoordinate()),
    );
    if (coordinatesText != null) {
      setState(() {
        _gpsLinkController.text = coordinatesText;
      });
    }
  }
}
