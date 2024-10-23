import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent overlay background
        // Container(
        //   color: Colors.white, // semi-transparent background
        // ),
        // Centered loading indicator
        Center(
          child: SpinKitChasingDots(
            color: Colors.white, // Adjusted for a clearer shade
            size: 80.0, // Adjusted size
          ),
        ),
      ],
    );
  }
}
