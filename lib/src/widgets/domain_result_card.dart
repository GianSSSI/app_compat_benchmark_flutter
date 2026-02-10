import 'package:flutter/material.dart';

class DomainResultCard extends StatelessWidget {
  final String title;
  final String score;
  final bool incompatible;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isOverallScore;

  const DomainResultCard({
    super.key,
    required this.title,
    required this.score,
    this.incompatible = false,
    this.backgroundColor,
    this.isOverallScore = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: incompatible ? Colors.red.shade100 : backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isOverallScore ? 4 : 2,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Text(title),
              const Spacer(),
              Text(
                incompatible ? 'Incompatible' : score,
                style: incompatible
                    ? const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
