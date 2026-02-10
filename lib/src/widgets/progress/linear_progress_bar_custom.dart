import 'package:flutter/material.dart';

class StaticProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String text;
  final double fontSize;
  const StaticProgressBar({
    super.key,
    required this.progress,
    required this.text,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            // Background
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // Progress
            Container(
              width: width * progress,
              height: height,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // Text
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
