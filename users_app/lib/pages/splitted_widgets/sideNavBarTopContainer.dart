
import 'package:flutter/material.dart';
import 'package:users_app/global/global.dart';

class SideNavBarTopContainer extends StatelessWidget {
  const SideNavBarTopContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      height: 160,
      child: DrawerHeader(
        decoration: const BoxDecoration(
          color: Colors.white10,
        ),
        child: Row(
          children: [
            Image.asset(
              "assets/images/avatarman.png",
              width: 60,
              height: 60,
            ),
            const SizedBox(
              width: 16,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                const Text(
                  "Profile",
                  style: TextStyle(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
