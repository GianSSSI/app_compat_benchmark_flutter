import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:flutter/material.dart';

class BenchMarkRunningOverlay extends StatelessWidget {
  final BenchmarkStepType step;

  const BenchMarkRunningOverlay({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Running: ${step.name}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
