import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:users_app/appInfo/appInfo.dart';
import 'package:users_app/authentication/login_screen.dart';
import 'package:users_app/authentication/signup_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:users_app/firebase_options.dart';
import 'package:users_app/pages/home_page.dart';
void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Permission.locationWhenInUse.isDenied.then((valueOfPermission){
    if(valueOfPermission)
    {
      Permission.locationWhenInUse.request();
    }
  });
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=>AppInfo(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black
        ),
        home: FirebaseAuth.instance.currentUser==null? LoginScreen():HomePage(),
      ),
    );
  
  }
}