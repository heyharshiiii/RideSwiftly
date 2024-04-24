import 'package:flutter/material.dart';

class SignOutWidget extends StatelessWidget {
  final VoidCallback signOut;
  const SignOutWidget({super.key, required this.signOut});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
                onTap: () {
                  signOut();

                  // Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                },
                child: ListTile(
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.logout,
          color: Colors.grey,
        ),
      ),
      title: const Text(
        "Logout",
        style: TextStyle(color: Colors.grey),
      ),
    ),
              );
  }
}