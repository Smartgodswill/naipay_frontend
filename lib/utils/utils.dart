import 'package:flutter/material.dart';

Widget customContainer (double height, double width, BoxDecoration decoration,Widget?child ){
  return Container(
    height:height ,
    width: width,
    decoration: decoration,
    child: child,
  );
}

Widget customButtonContainer (double height, double width, BoxDecoration decoration,Widget?child, Function()? ontap ){
  return InkWell(
    onTap:ontap ,
    child: Container(
      height:height ,
      width: width,
      decoration: decoration,
      child: child,
    ),
  );
}

  void customSnackBar(String message,BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

   customDialog(BuildContext context,String text){
     showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Registration Failed"),
              content: Text(text),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );

   }

  


