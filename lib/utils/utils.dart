import 'package:flutter/material.dart';
import 'package:naipay/theme/colors.dart';

Widget customContainer(
  double height,
  double width,
  BoxDecoration decoration,
  Widget? child,
) {
  return Container(
    height: height,
    width: width,
    decoration: decoration,
    child: child,
  );
}

Widget customButtonContainer(
  double height,
  double width,
  BoxDecoration decoration,
  Widget? child,
  Function()? ontap,
) {
  return InkWell(
    onTap: ontap,
    child: Container(
      height: height,
      width: width,
      decoration: decoration,
      child: child,
    ),
  );
}

void customSnackBar(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

customDialog(BuildContext context, String text) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: ksubcolor,
      title: const Text("Oops!"),
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

List<String> images = [
  'asset/write.json',
  'asset/play.json',
  'asset/origins.json',
  'asset/learn.json',
];
List<String> earnText = [
  'Write & earn',
  'Play games & earn',
  'Origin of BTC',
  'Learn & get paid',
];
