import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  String messageText;
  LoadingDialog({super.key, required this.messageText});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black87,
      child: Container(
        margin: EdgeInsets.all(15),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.black87, borderRadius: BorderRadius.circular(5)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(width: 5,),
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white),),
              SizedBox(width: 8,),
              Text(messageText,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
