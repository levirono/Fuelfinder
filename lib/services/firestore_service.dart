import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ff_main/models/fuel_station.dart';
// import 'package:ff_main/models/station_services.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


   Stream<List<FuelStation>> streamStations() {
    try {
      var snapshots = _db.collection('fuelStations').snapshots();

      return snapshots.asyncMap((querySnapshot) async {
        List<FuelStation> stations = [];

        for (var doc in querySnapshot.docs) {
          var stationData = doc.data() as Map<String, dynamic>;
          var stationId = doc.id;

          // Fetch station services data for the current station
          var services = await getStationServices(stationId);

          // Create FuelStation object with station name and services data
          var fuelStation = FuelStation.fromMap({
            ...stationData,
            'id': stationId,
            'isPetrolAvailable': services.isPetrolAvailable,
            'isDieselAvailable': services.isDieselAvailable,
            'isOpen': services.isOpen,
          });

          stations.add(fuelStation);
        }

        return stations;
      });
    } catch (e) {
      throw Exception('Error streaming stations: $e');
    }
  }
Stream<List<FuelStation>> streamStationsWithServices() {
  try {
    return _db.collection('fuelStations').snapshots().asyncMap((querySnapshot) async {
      List<FuelStation> stations = [];

      for (var doc in querySnapshot.docs) {
        var stationData = doc.data() as Map<String, dynamic>;
        var stationId = doc.id;

        // Fetch station services data for the current station
        var services = await getStationServices(stationId);

        // Create FuelStation object with station details and services data
        var fuelStation = FuelStation.fromMap({
          ...stationData,
          'id': stationId,
          'isPetrolAvailable': services.isPetrolAvailable,
          'isDieselAvailable': services.isDieselAvailable,
          'isOpen': services.isOpen,
        });

        stations.add(fuelStation);
      }

      return stations;
    });
  } catch (e) {
    throw Exception('Error streaming stations with services: $e');
  }
}



  Future<void> addOrUpdateStation(FuelStation station, String ownerId) async {
    try {
      await _db.collection('fuelStations').doc(station.id).set({
        ...station.toMap(),
        'ownerId': ownerId,
      });
    } catch (e) {
      throw Exception('Error updating station: $e');
    }
  }

  Future<FuelStation?> getStationByOwnerId(String ownerId) async {
    try {
      var querySnapshot = await _db
          .collection('fuelStations')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        return FuelStation.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
    } catch (e) {
      throw Exception('Error fetching station by owner ID: $e');
    }
    return null;
  }

  Stream<List<FuelStation>> streamStationsForOwner(String ownerId) {
    try {
      var snapshots = _db
          .collection('fuelStations')
          .where('ownerId', isEqualTo: ownerId)
          .snapshots();

      return snapshots.map((querySnapshot) => querySnapshot.docs
          .map((doc) => FuelStation.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList());
    } catch (e) {
      throw Exception('Error streaming stations for owner: $e');
    }
  }

  Future<void> updateStationServices(String stationId, StationServices services) async {
    try {
      await _db.collection('stationServices').doc(stationId).set({
        'isPetrolAvailable': services.isPetrolAvailable,
        'isDieselAvailable': services.isDieselAvailable,
        'petrolPrice': services.petrolPrice,
        'dieselPrice': services.dieselPrice,
        'isOpen': services.isOpen,
        'availableServices': services.availableServices,
      });
    } catch (e) {
      throw Exception('Error updating station services: $e');
    }
  }
   Future<List<String>> getServicesOffered(String stationId) async {
    try {
      var docSnapshot = await _db.collection('fuelStations').doc(stationId).get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> servicesData = data['servicesOffered'] ?? [];

        return servicesData.map((service) => service.toString()).toList();
      }
    } catch (e) {
      throw Exception('Error fetching services offered: $e');
    }
    return [];
  }
  Future<String?> getStationName(String stationId) async {
  try {
    var docSnapshot = await _db.collection('fuelStations').doc(stationId).get();

    if (docSnapshot.exists) {
      var data = docSnapshot.data() as Map<String, dynamic>;
      return data['name']?.toString(); // Use null-safe access operator (?)
    }
  } catch (e) {
    throw Exception('Error fetching station name: $e');
  }
  return null; // Return null if station not found or error occurs
}


  Future<StationServices> getStationServices(String stationId) async {
    try {
      // Fetch the station services document using the provided stationId
      var docSnapshot = await _db.collection('stationServices').doc(stationId).get();

      if (docSnapshot.exists) {
        // If the station services document exists, parse the data into a StationServices object
        var servicesData = docSnapshot.data() as Map<String, dynamic>;
        return StationServices(
          isPetrolAvailable: servicesData['isPetrolAvailable'],
          isDieselAvailable: servicesData['isDieselAvailable'],
          petrolPrice: servicesData['petrolPrice'].toDouble(),
          dieselPrice: servicesData['dieselPrice'].toDouble(),
          isOpen: servicesData['isOpen'],
          availableServices: List<String>.from(servicesData['availableServices']),
        );
      } else {
        // If the station services document doesn't exist, create a new one with defaults
        await _db.collection('stationServices').doc(stationId).set({
          'isPetrolAvailable': false,
          'isDieselAvailable': false,
          'petrolPrice': 0.0,
          'dieselPrice': 0.0,
          'isOpen': false,
          'availableServices': [],
        });
        return StationServices(
          isPetrolAvailable: false,
          isDieselAvailable: false,
          petrolPrice: 0.0,
          dieselPrice: 0.0,
          isOpen: false,
          availableServices: [],
        );
      }
    } catch (e) {
      throw Exception('Error fetching station services: $e');
    }
  }

Stream<List<FuelEfficiencyTip>> streamFuelEfficiencyTips() {
    return _db.collection('fuel_efficiency_tips').orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FuelEfficiencyTip.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addFuelEfficiencyTip(String tip) async {
  try {
    final CollectionReference tipsCollection = FirebaseFirestore.instance.collection('fuel_efficiency_tips');

    // Check if the collection exists by retrieving its metadata
    final CollectionReference metadataCollection = FirebaseFirestore.instance.collection('fuel_efficiency_tips');
    final QuerySnapshot metadataQuery = await metadataCollection.limit(1).get();

    if (metadataQuery.docs.isEmpty) {
      // The collection does not exist, Firestore will create it automatically
      print('The fuel_efficiency_tips collection does not exist yet.');
    }

    // Add the tip to the collection
    await tipsCollection.add({
      'tip': tip,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    print('Fuel efficiency tip added successfully.');

  } catch (e) {
    // Log the error or use a more sophisticated error handling approach
    print('Error adding tip: $e');
  }
}
Future<List<FuelEfficiencyTip>> getFuelEfficiencyTips() async {
    try {
      final QuerySnapshot querySnapshot = await _db.collection('fuel_efficiency_tips')
                                                     .orderBy('timestamp', descending: true)
                                                     .get();

      return querySnapshot.docs.map((doc) {
        return FuelEfficiencyTip.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching fuel efficiency tips: $e');
    }
  }
  Future<Driver?> getDriverByOwnerId(String ownerId) async {
    var snapshot = await _db.collection('drivers').where('ownerId', isEqualTo: ownerId).get();
    if (snapshot.docs.isNotEmpty) {
      return Driver.fromSnapshot(snapshot.docs.first);
    }
    return null;
  }

  Future<void> addOrUpdateDriver(Driver driver, String ownerId) async {
    await _db.collection('drivers').doc(driver.id).set({
      'name': driver.name,
      'phoneNumber': driver.phoneNumber,
      'vehicleModel': driver.vehicleModel,
      'vehiclePlateNumber': driver.vehiclePlateNumber,
      'driverLicense': driver.driverLicense,
      'ownerId': ownerId,
    });
  }

  Future<void> deleteDriver(String driverId, String ownerId) async {
    await _db.collection('drivers').doc(driverId).delete();
  }
}

