import 'package:flutter/material.dart';

class SideNavBarBottomContainer extends StatelessWidget {
  const SideNavBarBottomContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.info,
          color: Colors.grey,
        ),
      ),
      title: const Text(
        "About",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}