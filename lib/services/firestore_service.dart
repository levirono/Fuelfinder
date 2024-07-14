import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ff_main/models/fuelfinder.dart';
import 'package:ff_main/utils/notifications.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();


  Stream<List<FuelStation>> streamStations() {
    try {
      var snapshots = _db.collection('fuelStations').snapshots();

      return snapshots.asyncMap((querySnapshot) async {
        List<FuelStation> stations = [];

        for (var doc in querySnapshot.docs) {
          var stationData = doc.data();
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
      return _db
          .collection('fuelStations')
          .snapshots()
          .asyncMap((querySnapshot) async {
        List<FuelStation> stations = [];

        for (var doc in querySnapshot.docs) {
          var stationData = doc.data();
          var stationId = doc.id;

          var services = await getStationServices(stationId);

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

  Stream<List<FuelStation>> streamVerifiedStations() {
    try {
      var snapshots = _db
          .collection('fuelStations')
          .where('isVerified', isEqualTo: true)
          .snapshots();

      return snapshots.asyncMap((querySnapshot) async {
        List<FuelStation> stations = [];

        for (var doc in querySnapshot.docs) {
          var stationData = doc.data();
          var stationId = doc.id;

          var services = await getStationServices(stationId);

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
      throw Exception('Error streaming verified stations: $e');
    }
  }
//new stations notification
   Future<bool> checkForNewStations() async {
    DateTime lastCheckedTime = DateTime.now().subtract(const Duration(hours: 24));

    var newStationsQuery = await _db
        .collection('fuelStations')
        .where('createdAt', isGreaterThan: lastCheckedTime)
        .get();

    int newStationsCount = newStationsQuery.docs.length;

    if (newStationsCount > 0) {
      // Send notification to admin users
      await _notificationService.showNotification(
        'New Stations Registered',
        '$newStationsCount new stations have registered and are waiting for verification.',
      );
      return true;
    }
    return false;
  }


  Stream<bool> getVerificationStatusStream(String stationId) {
    return _db.collection('stations')
      .doc(stationId)
      .snapshots()
      .map((snapshot) => snapshot.data()?['isVerified'] as bool);
  }
  Stream<StationServices> streamStationServices(String stationId) {
    return FirebaseFirestore.instance
        .collection('stationServices')
        .doc(stationId)
        .snapshots()
        .map((snapshot) => StationServices.fromMap(snapshot.data()!));
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

  Future<bool> updateStationVerificationStatus(String stationId, bool isVerified) async {
  try {
    await _db.collection('fuelStations').doc(stationId).update({
      'isVerified': isVerified,
    });
    return true;
  } catch (e) {
    print('Error updating verification status: $e');
    return false;
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
          ...doc.data(),
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
                ...doc.data(),
                'id': doc.id,
              }))
          .toList());
    } catch (e) {
      throw Exception('Error streaming stations for owner: $e');
    }
  }

  Future<void> updateStationServices(
      String stationId, StationServices services) async {
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
      var docSnapshot =
          await _db.collection('fuelStations').doc(stationId).get();

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
      var docSnapshot =
          await _db.collection('fuelStations').doc(stationId).get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        return data['name']?.toString();
      }
    } catch (e) {
      throw Exception('Error fetching station name: $e');
    }
    return null;
  }

  Future<StationServices> getStationServices(String stationId) async {
    try {
      var docSnapshot =
          await _db.collection('stationServices').doc(stationId).get();

      if (docSnapshot.exists) {
        var servicesData = docSnapshot.data() as Map<String, dynamic>;
        return StationServices(
          isPetrolAvailable: servicesData['isPetrolAvailable'],
          isDieselAvailable: servicesData['isDieselAvailable'],
          petrolPrice: servicesData['petrolPrice'].toDouble(),
          dieselPrice: servicesData['dieselPrice'].toDouble(),
          isOpen: servicesData['isOpen'],
          availableServices:
              List<String>.from(servicesData['availableServices']),
        );
      } else {
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
    return _db
        .collection('fuel_efficiency_tips')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FuelEfficiencyTip.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> deleteStation(String stationId) async {
    await _db.collection('fuelStations').doc(stationId).delete();
  }

  Future<void> addFuelEfficiencyTip(String tip) async {
    try {
      final CollectionReference tipsCollection =
          FirebaseFirestore.instance.collection('fuel_efficiency_tips');
      final CollectionReference metadataCollection =
          FirebaseFirestore.instance.collection('fuel_efficiency_tips');
      final QuerySnapshot metadataQuery =
          await metadataCollection.limit(1).get();

      if (metadataQuery.docs.isEmpty) {}

      await tipsCollection.add({
        'tip': tip,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      // print('Error adding tip: $e');
    }
  }

  Future<List<FuelEfficiencyTip>> getFuelEfficiencyTips() async {
    try {
      final QuerySnapshot querySnapshot = await _db
          .collection('fuel_efficiency_tips')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return FuelEfficiencyTip.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching fuel efficiency tips: $e');
    }
  }
  
  Future<void> updateFuelEfficiencyTip(String tipId, String updatedTip) async {
    try {
      await _db.collection('fuel_efficiency_tips').doc(tipId).update({
        'tip': updatedTip,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating fuel efficiency tip: $e');
    }
  }

  Future<void> deleteFuelEfficiencyTip(String tipId) async {
    try {
      await _db.collection('fuel_efficiency_tips').doc(tipId).delete();
    } catch (e) {
      throw Exception('Error deleting fuel efficiency tip: $e');
    }
  }


  Future<Driver?> getDriverByOwnerId(String ownerId) async {
    var snapshot = await _db
        .collection('drivers')
        .where('ownerId', isEqualTo: ownerId)
        .get();
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

  Future<void> deleteDriver(String driverId) async {
    try {
      await _db.collection('drivers').doc(driverId).delete();
    } catch (e) {
      throw Exception('Error deleting driver: $e');
    }
  }

  Stream<List<Driver>> streamDrivers() {
    try {
      var snapshots = _db.collection('drivers').snapshots();

      return snapshots.map((querySnapshot) =>
          querySnapshot.docs.map((doc) => Driver.fromSnapshot(doc)).toList());
    } catch (e) {
      throw Exception('Error streaming drivers: $e');
    }
  }

  Future<int> getStationCount() async {
    try {
      var querySnapshot = await _db.collection('fuelStations').get();
      return querySnapshot.size;
    } catch (e) {
      throw Exception('Error fetching station count: $e');
    }
  }

  Future<int> getDriverCount() async {
    try {
      var querySnapshot = await _db.collection('drivers').get();
      return querySnapshot.size;
    } catch (e) {
      throw Exception('Error fetching driver count: $e');
    }
  }

  Future<void> verifyStation(String stationId, bool isVerified) async {
    try {
      await _db
          .collection('fuelStations')
          .doc(stationId)
          .update({'isVerified': isVerified});
    } catch (e) {
      rethrow;
    }
  }
}
