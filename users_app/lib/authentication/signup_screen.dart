import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:users_app/authentication/login_screen.dart';
import 'package:users_app/methods/common_methods.dart';
import 'package:users_app/pages/home_page.dart';
import 'package:users_app/widgets/loading_dialog.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _phonenoController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);
    signUpFormValidation();
  }

  signUpFormValidation() {
    if (_phonenoController.text.trim().length < 10) {
      cMethods.displaySnackBar("Phone number must be  10 digits", context);
    } else
     if (!_emailController.text.contains("@")) {
      cMethods.displaySnackBar("Enter a valid email", context);
    } else if (_passwordController.text.trim().length < 5) {
      cMethods.displaySnackBar("Password must be 6 characters", context);
    } else {
      registerNewUser();
    }
  }

  registerNewUser() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Registering Your Account..."));
    final User? userFirebase = (await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    )
            .catchError((errorMsg) {
      Navigator.pop(context);
      cMethods.displaySnackBar(errorMsg.toString(), context);
    }))
        .user;
    if (!context.mounted) return;
    Navigator.pop(context);

    DatabaseReference usersRef=FirebaseDatabase.instance.ref().child("users").child(userFirebase!.uid);
    Map userDataMap=
    {
      "name":_usernameController.text.trim(),
      "email":_emailController.text.trim(),
      "phone":_phonenoController.text.trim(),
      "id":userFirebase.uid,
      "blockStatus":"no",
    };
    usersRef.set(userDataMap);
    Navigator.push(context,MaterialPageRoute(builder: (c)=>HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Center(
                  child: Image.asset(
                'assets/images/logo.png',
                height: 350,
                width: 350,
              )),
              const Text(
                "Create User\'s Account",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                          labelText: "User Name",
                          labelStyle: TextStyle(fontSize: 14)),
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: _phonenoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: "Phone Number",
                          labelStyle: TextStyle(fontSize: 14)),
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(fontSize: 14)),
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(fontSize: 14)),
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 12,
              ),
              ElevatedButton(
                onPressed: () {
                  checkIfNetworkIsAvailable();
                },
                child: Text("SIGN UP"),
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 80)),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (c) => LoginScreen()));
                        //Navigator.pop(context);
                      },
                      child: Text("Login Here"))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
