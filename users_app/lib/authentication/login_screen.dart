import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:users_app/authentication/signup_screen.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/methods/common_methods.dart';
import 'package:users_app/pages/home_page.dart';
import 'package:users_app/widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);
    signUpFormValidation();
  }
  signUpFormValidation()
  {
    if(!_emailController.text.contains("@"))
    {
        cMethods.displaySnackBar("Enter a valid email", context);
    }
    else if(_passwordController.text.trim().length<5)
    {
      cMethods.displaySnackBar("Password must be 6 characters", context);
    }
    else
    {
      logInUser();
    }
  }

  logInUser() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingDialog(messageText: "Logging you in..."));
    final User? userFirebase = (await FirebaseAuth.instance
            .signInWithEmailAndPassword(
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

        if(userFirebase!=null)
        {
          DatabaseReference usersRef=FirebaseDatabase.instance.ref().child("users").child(userFirebase.uid);
          usersRef.once().then((snap){
            if(snap.snapshot.value!=null)
            {
                if((snap.snapshot.value as Map)["blockStatus"]=="no")
                {
                  userName=(snap.snapshot.value as Map)["name"];
                  userPhone=(snap.snapshot.value as Map)["phone"];
                  Navigator.pushReplacement(context,MaterialPageRoute(builder: (c)=>HomePage()));
                }
                else
                {
                  FirebaseAuth.instance.signOut();
                  cMethods.displaySnackBar("You are blocked. Contact admin harshita@gmail.com", context);
                }
            }
            else
            {
              FirebaseAuth.instance.signOut();
              cMethods.displaySnackBar("Your record do not exist", context);
            }
          });
          
        }
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
                "Login as a User",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 22,
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
                      height: 22,
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
                height: 22,
              ),
              ElevatedButton(
                onPressed: () {
                  checkIfNetworkIsAvailable();
                },
                child: Text("LOG IN"),
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
                    "Dont have an account?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (c) => SignupScreen()));
                      },
                      child: Text("Register Here"))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
