import 'package:flutter/material.dart';
import 'package:naipay/theme/colors.dart';

class AnimatedVerifyIconPopup extends StatefulWidget {
  const AnimatedVerifyIconPopup({super.key});

  @override
  State<AnimatedVerifyIconPopup> createState() => _AnimatedVerifyIconPopupState();
}

class _AnimatedVerifyIconPopupState extends State<AnimatedVerifyIconPopup>
    with SingleTickerProviderStateMixin {
  bool _popped = false;

  @override
  void initState() {
    super.initState();

    // Trigger animation after widget builds
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _popped = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: Duration(milliseconds: 500),
      scale: _popped ? 1.2 : 0.0, // grows from 0 → 1.2
      curve: Curves.elasticOut, // gives a pop/bounce effect
      child: Icon(
        Icons.verified,
        color: kwhitecolor,
        size: 90,
      ),
    );
  }
}
