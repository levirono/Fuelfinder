import 'package:cloud_firestore/cloud_firestore.dart';

class FuelStation {
  String id;
  String name;
  String location;
  String gpsLink;
  List<String> servicesOffered;
  String operationHours;
  bool isVerified; // Add this property

  FuelStation({
    required this.id,
    required this.name,
    required this.location,
    required this.gpsLink,
    required this.servicesOffered,
    required this.operationHours,
    this.isVerified = false, // Initialize as false by default
  });

  factory FuelStation.fromMap(Map<String, dynamic> map) {
    return FuelStation(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      gpsLink: map['gpsLink'],
      servicesOffered: List<String>.from(map['servicesOffered']),
      operationHours: map['operationHours'],
      isVerified: map['isVerified'] ?? false, // Read the isVerified field
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'gpsLink': gpsLink,
      'servicesOffered': servicesOffered,
      'operationHours': operationHours,
      'isVerified': isVerified, // Include isVerified in the map
    };
  }
}

class StationServices {
  bool isPetrolAvailable;
  bool isDieselAvailable;
  double petrolPrice;
  double dieselPrice;
  bool isOpen;
  List<String> availableServices;

  StationServices({
    required this.isPetrolAvailable,
    required this.isDieselAvailable,
    required this.petrolPrice,
    required this.dieselPrice,
    required this.isOpen,
    required this.availableServices,
  });

  factory StationServices.fromMap(Map<String, dynamic> data) {
    return StationServices(
      isPetrolAvailable: data['isPetrolAvailable'] ?? false,
      isDieselAvailable: data['isDieselAvailable'] ?? false,
      petrolPrice: (data['petrolPrice'] ?? 0.0).toDouble(),
      dieselPrice: (data['dieselPrice'] ?? 0.0).toDouble(),
      isOpen: data['isOpen'] ?? false,
      availableServices: List<String>.from(data['availableServices'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPetrolAvailable': isPetrolAvailable,
      'isDieselAvailable': isDieselAvailable,
      'petrolPrice': petrolPrice,
      'dieselPrice': dieselPrice,
      'isOpen': isOpen,
      'availableServices': availableServices,
    };
  }
}


class FuelEfficiencyTip {
  final String id;
  final String tip;
  final DateTime timestamp;

  FuelEfficiencyTip({required this.id, required this.tip, required this.timestamp});

  factory FuelEfficiencyTip.fromMap(Map<String, dynamic> map, String documentId) {
    return FuelEfficiencyTip(
      id: documentId,
      tip: map['tip'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tip': tip,
      'timestamp': timestamp,
    };
  }
}

class Driver {
  String id;
  String name;
  String phoneNumber;
  String vehicleModel;
  String vehiclePlateNumber;
  String driverLicense;

  Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.vehicleModel,
    required this.vehiclePlateNumber,
    required this.driverLicense,
  });

  factory Driver.fromSnapshot(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Driver(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      vehiclePlateNumber: data['vehiclePlateNumber'] ?? '',
      driverLicense: data['driverLicense'] ?? '',
    );
  }
}