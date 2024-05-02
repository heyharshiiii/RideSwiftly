import 'dart:io';
import 'package:drivers_app/authentication/login_screen.dart';
import 'package:drivers_app/methods/common_methods.dart';
import 'package:drivers_app/pages/dashboard.dart';
import 'package:drivers_app/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _drivernameController = TextEditingController();
  TextEditingController _phonenoController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _vehicleModelController = TextEditingController();
  TextEditingController _vehicleNumberController = TextEditingController();
  TextEditingController _vehicleColorController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage="";
  checkIfNetworkIsAvailable() async{
    await cMethods.checkConnectivity(context);
    // if(imageFile!=null)
    // {
      signUpFormValidation();
    //}
    // else
    // {
    //   cMethods.displaySnackBar("Please choose an image", context);
    // }
  }

  signUpFormValidation() {
    if (_phonenoController.text.trim().length < 10) {
      cMethods.displaySnackBar("Phone number must be  10 digits", context);
    } else if (!_emailController.text.contains("@")) {
      cMethods.displaySnackBar("Enter a valid email", context);
    } else if (_passwordController.text.trim().length < 5) {
      cMethods.displaySnackBar("Password must be 6 characters", context);
    }
    else if(_vehicleNumberController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please Enter Car Number", context);
    }
    else if(_vehicleModelController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please Enter Car Model", context);
    }
    else if(_vehicleColorController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please Enter Car Color", context);
    }
    else {
      //uploadImageToStorage();
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

    DatabaseReference usersRef =
        FirebaseDatabase.instance.ref().child("drivers").child(userFirebase!.uid);
    Map driverVehicleInfo={
      "vehicleColor":_vehicleColorController.text.trim(),
      "vehicleModel":_vehicleModelController.text.trim(),
      "vehicleNumber":_vehicleNumberController.text.trim(),
    };
    Map userDataMap = {
      "photo":"",
      "name": _drivernameController.text.trim(),
      "car_details": driverVehicleInfo,
      "email": _emailController.text.trim(),
      "phone": _phonenoController.text.trim(),
      "id": userFirebase.uid,
      "blockStatus": "no",
    };
    usersRef.set(userDataMap);
    Navigator.push(context, MaterialPageRoute(builder: (c) => Dashboard()));
  }

  chooseImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile;
      });
    }
  }

  uploadImageToStorage() async
  {
    String imageIDname=DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImage=FirebaseStorage.instance.ref().child("Images").child(imageIDname);

   UploadTask uploadTask= referenceImage.putFile(File(imageFile!.path));
   TaskSnapshot snapshot=await uploadTask;
   urlOfUploadedImage= await snapshot.ref.getDownloadURL();
   setState(() {
     urlOfUploadedImage;
   });
   registerNewUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 80,
              ),
              imageFile == null
                  ? CircleAvatar(
                      radius: 80,
                      backgroundImage:
                          AssetImage("assets/images/avatarman.png"),
                    )
                  : Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: FileImage(
                              File(imageFile!.path),
                            ),
                          )),
                    ),
              SizedBox(
                height: 1,
              ),
              TextButton(
                onPressed: () {
                  chooseImageFromGallery();
                },
                child: Text("Select Image"),
              ),
              SizedBox(
                height: 20,
              ),
              const Text(
                "Create Driver\'s Account",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _drivernameController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                          labelText: "Driver Name",
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
                    TextField(
                      controller: _vehicleNumberController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                          labelText: "Vehicle Number",
                          labelStyle: TextStyle(fontSize: 14)),
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: _vehicleModelController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                          labelText: "Vehicle Model",
                          labelStyle: TextStyle(fontSize: 14)),
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: _vehicleColorController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                          labelText: "Vehicle Color",
                          labelStyle: TextStyle(fontSize: 14)),
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    SizedBox(
                      height: 12,
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
