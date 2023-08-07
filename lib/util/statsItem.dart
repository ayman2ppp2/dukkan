import 'package:flutter/material.dart';

class Sitem extends StatelessWidget {
  final Widget child;
  const Sitem({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[200],
        borderRadius: BorderRadius.circular(50),
      ),
      child: child,
    );
  }
}
