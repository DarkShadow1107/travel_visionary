import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String destination;

  const FullScreenImageView({Key? key, required this.destination})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imagePath = 'assets/assets/home/$destination.jpg';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(); // Dismiss when tapping the background
      },
      child: Scaffold(
        backgroundColor:
            Colors
                .transparent, // Crucial for the backdrop filter to show through
        body: Stack(
          children: [
            // Blurred background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(
                    0.7,
                  ), // Dark semi-transparent overlay
                ),
              ),
            ),
            // Image content
            Center(
              child: GestureDetector(
                onTap: () {
                  // Do nothing on image tap, to prevent accidental dismissal if user meant to interact with image
                },
                child: Container(
                  width: screenSize.width * 0.8,
                  height: screenSize.height * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit:
                          BoxFit
                              .contain, // Use contain to ensure the whole image is visible
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Optional: Close button
            Positioned(
              top: 40,
              right: 20,
              child: Material(
                // Material widget for InkWell splash effect and theming
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}