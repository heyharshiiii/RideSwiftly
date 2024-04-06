import 'package:admin_webapp/dashboard/side_navigation_drawer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCgIJEQ1X_8ueneWTHklDV55IGmnnlYel8",
  authDomain: "rideswiftly-ceb15.firebaseapp.com",
  databaseURL: "https://rideswiftly-ceb15-default-rtdb.firebaseio.com",
  projectId: "rideswiftly-ceb15",
  storageBucket: "rideswiftly-ceb15.appspot.com",
  messagingSenderId: "163937758802",
  appId: "1:163937758802:web:a99f5e63f881877206398b",
  measurementId: "G-91Z7G7SE9P"
          
          ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: SideNavigationDrawer(),
    );
  }
}
