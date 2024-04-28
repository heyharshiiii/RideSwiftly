import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';

class InfoDialog extends StatefulWidget {
  String title;
  String description;
 InfoDialog({super.key,required this.title, required this.description});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Colors.black,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 12,
                ),
                Text(
                  widget.title.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 27,
                ),
                Text(
                  widget.description.toString(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 32,
                ),
                SizedBox(
                  width: 202,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Restart.restartApp();
                    },
                    child: Text("OK"),
                  ),
                ),
                 SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
