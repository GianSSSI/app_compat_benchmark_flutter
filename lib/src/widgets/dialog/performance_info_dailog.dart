import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:flutter/material.dart';

class PerformanceInfoDialog extends StatefulWidget {
  final PerformanceDomainScore performanceDomainScore;

  const PerformanceInfoDialog({
    super.key,
    required this.performanceDomainScore,
  });

  @override
  _PerformanceInfoDialogState createState() => _PerformanceInfoDialogState();
}

class _PerformanceInfoDialogState extends State<PerformanceInfoDialog> {
  final Set<int> expandedIndexes = {};

  BenchmarkStepResult? _findResult(BenchmarkStepType type) {
    try {
      return widget.performanceDomainScore.results.firstWhere(
        (r) => r.type == type,
      );
    } catch (_) {
      return null;
    }
  }

  String bytesToGb(double bytes) =>
      (bytes / (1024 * 1024 * 1024)).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Performance Details",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 350,
              child: ListView.separated(
                itemCount: widget.performanceDomainScore.stepScores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final stepScore =
                      widget.performanceDomainScore.stepScores[index];
                  final result = _findResult(stepScore.stepType);
                  final isExpanded = expandedIndexes.contains(index);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedIndexes.remove(index);
                        } else {
                          expandedIndexes.add(index);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Collapsed row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stepScore.stepType.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  stepScore.totalScore?.toStringAsFixed(2) ??
                                      "N/A",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.grey,
                              ),
                            ],
                          ),

                          // Expanded content
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            if (result == null)
                              const Text("No data available")
                            else
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(3),
                                },
                                children: [
                                  _buildTableRow(
                                    "FPS",
                                    result.fps.toStringAsFixed(2),
                                  ),
                                  _buildTableRow(
                                    "Frame Time",
                                    "${result.frameTime.toStringAsFixed(2)} ms",
                                  ),
                                  _buildTableRow(
                                    "CPU",
                                    "${result.cpuUsage.toStringAsFixed(2)}%",
                                  ),
                                  _buildTableRow(
                                    "Memory",
                                    "${bytesToGb(result.memoryUsage)} GB",
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  "Overall Performance Score:",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  widget.performanceDomainScore.overallScore.toStringAsFixed(2),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(value),
        ),
      ],
    );
  }
}
