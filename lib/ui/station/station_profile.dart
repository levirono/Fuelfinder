import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ff_main/services/firestore_service.dart';
import 'package:ff_main/models/fuel_station.dart';
import 'package:uuid/uuid.dart';
import 'package:ff_main/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ff_main/ui/station/pick_my_coordinates.dart';
import 'package:ff_main/ui/station/station_homepage.dart';

class StationProfile extends StatefulWidget {
  @override
  _StationProfileState createState() => _StationProfileState();
}

class _StationProfileState extends State<StationProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _gpsLinkController = TextEditingController();
  final _servicesOfferedController = TextEditingController();
  final _operationHoursController = TextEditingController();
  final _roadCodeController = TextEditingController();
  final _routeController = TextEditingController();
  final _distanceToController = TextEditingController();
  final _distanceFromController = TextEditingController();

  final _authService = AuthService();

  FuelStation? _existingStation;
  bool _editMode = false;

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
    _locationController.text = _existingStation!.location;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Station Profile'),
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
                _buildFormField('Station Name', _nameController, mandatory: true),
                _buildFormField('Location', _locationController),
                _buildFormField('GPS Link', _gpsLinkController, mandatory: true, example: 'latitude,longitude'),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _openPickMyCoordinateScreen,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    minimumSize: Size(double.infinity, 40.0),
                  ),
                  child: Text(
                    'Pick My Coordinates',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                _buildFormField('Road Code', _roadCodeController, mandatory: true, example: 'C39'),
                _buildFormField('Route', _routeController, mandatory: true, example: 'Eldoret-kapsabet'),
                _buildFormField('Distance To (km)', _distanceToController),
                _buildFormField('Distance From (km)', _distanceFromController),
                _buildFormField('Services Offered (comma-separated)', _servicesOfferedController),
                _buildFormField('Operation Hours', _operationHoursController),
                SizedBox(height: 20.0),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String labelText, TextEditingController controller, {bool mandatory = false, String example = ''}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                labelText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (mandatory) Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
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
          primary: Colors.lightGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
          ),
          minimumSize: Size(double.infinity, 40.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: Colors.white),
            SizedBox(width: 8.0),
            Text(
              'Save Station Profile',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () => setState(() => _editMode = true),
        style: ElevatedButton.styleFrom(
          primary: Colors.lightGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          minimumSize: Size(double.infinity, 40.0),
        ),
        child: Row(
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

  Future<Position?> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error fetching location: $e');
      return null;
    }
  }

  void _updateGPSLink(Position position) {
    String gpsCoordinates = '${position.latitude},${position.longitude}';
    _gpsLinkController.text = gpsCoordinates;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      User? currentUser = await _authService.getCurrentUser();
     
          if (currentUser == null) {
        return;
      }

      String stationId = _existingStation?.id ?? Uuid().v4();

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
          .showSnackBar(SnackBar(content: Text('Station profile saved')));
      _loadStationProfile();
    }
  }

  void _openPickMyCoordinateScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PickMyCoordinate()),
    );
  }
}
