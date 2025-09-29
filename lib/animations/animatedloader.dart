// New AnimatedLoadingDots widget
import 'package:flutter/material.dart';
import 'package:naipay/theme/colors.dart';

class AnimatedLoadingDots extends StatefulWidget {
  @override
  _AnimatedLoadingDotsState createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<AnimatedLoadingDots> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _dotAnimation = IntTween(begin: 1, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '....' * _dotAnimation.value,
            style: TextStyle(fontSize: 20, color: kwhitecolor),
          ),
        );
      },
    );
  }
}