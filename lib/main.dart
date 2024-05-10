import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ff_main/services/auth.dart';
import 'package:ff_main/services/login_page.dart';
import 'package:ff_main/ui/driver/driver_homepage.dart';
import 'package:ff_main/ui/station/station_homepage.dart';
// import 'package:permission_handler/permission_handler.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
// Future <bool>requestCameraPermission() async {
//   if (awaitPermission.camera.request()isGranted){
//     return true;
//   }
//   else{
//     return false;
//   }
// }
// Future <bool>requestLocationPermission() async {
//   if (awaitPermission.Location.request()isGranted){
//     return true;
//   }
//   else{
//     return false;
//   }
// }
// Future <bool>requestStoragePermission() async {
//   if (awaitPermission.storage.request()isGranted){
//     return true;
//   }
//   else{
//     return false;
//   }
// }
class MyApp extends StatelessWidget {
  // bool locationPermissionGranted= await requestLocationPermission();
  // bool storagePermissionGranted= await requestStoragePermission();
  // bool cameraPermissionGranted= await requestCameraPermission();


  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Wrap with MaterialApp
      title: 'Your App Title',
      home: StreamBuilder<User?>(
        stream: _authService.currentUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final user = snapshot.data;
            if (user != null) {
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(user.uid).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (userSnapshot.hasError) {
                    return Text('Error retrieving user data');
                  } else {
                    final userData = userSnapshot.data;
                    if (userData != null && userData.exists) {
                      final role = userData['role'] as String?;
                      if (role == 'user') {
                        return DriverHomePage();
                      } else if (role == 'station') {
                        return StationHomePage();
                      } else {
                        return Text('Unknown role');
                      }
                    } else {
                      return Text('User data not found');
                    }
                  }
                },
              );
            } else {
              return LoginPage();
            }
          }
        },
      ),
    );
  }
}
