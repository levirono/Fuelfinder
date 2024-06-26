import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/login_page.dart';
import 'package:ff_main/ui/driver/driver_homepage.dart';
import 'package:ff_main/ui/station/station_homepage.dart';
import 'package:ff_main/ui/admin/admin_dashboard.dart';
//added these 2
import 'package:workmanager/workmanager.dart';
import 'package:ff_main/services/firestore_service.dart';




//added this part
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    FirestoreService firestoreService = FirestoreService();
    await firestoreService.checkForNewStations();
    return Future.value(true);
  });
}
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
//added this part
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Workmanager().registerPeriodicTask(
    "1",
    "checkNewStations",
    frequency: Duration(minutes: 4),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      home: FutureBuilder<PermissionStatus>(
        future: Permission.location.request(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LogoLoading());
          } else {
            final locationStatus = snapshot.data;
            if (locationStatus == PermissionStatus.granted) {
              return buildMainInterface();
            } else if (locationStatus == PermissionStatus.denied) {
              return const Scaffold(
                body: Center(
                  child: Text('This permission is required to use FUELFINDER'),
                ),
              );
            } else if (locationStatus == PermissionStatus.permanentlyDenied) {
              openAppSettings();
              return Container();
            } else {
              return const Scaffold(
                body: Center(
                  child: Text('Unknown permission status'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget buildMainInterface() {
    return StreamBuilder<User?>(
      stream: _authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LogoLoading());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final user = snapshot.data;
          if (user != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LogoLoading());
                } else if (userSnapshot.hasError) {
                  return const Text('Error retrieving user data');
                } else {
                  final userData = userSnapshot.data;
                  if (userData != null && userData.exists) {
                    final role = userData['role'] as String?;
                    if (role == 'user') {
                      return const DriverHomePage();
                    } else if (role == 'station') {
                      return const StationHomePage();
                    } else if (role == 'admin') {
                      return const AdminDashboard();
                    } else {
                      return const Text('Unknown role');
                    }
                  } else {
                    return const Text('User data not found');
                  }
                }
              },
            );
          } else {
            return const LoginPage();
          }
        }
      },
    );
  }
}

class LogoLoading extends StatelessWidget {
  const LogoLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Image.asset('assets/loading.png'),
      ),
    );
  }
}
