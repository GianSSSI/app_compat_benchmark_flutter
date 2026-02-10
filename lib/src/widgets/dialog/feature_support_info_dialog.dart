import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:flutter/material.dart';

class FeatureSupportInfoDialog extends StatefulWidget {
  final FeatureSupportScore featureSupportScore;
  final List<FeatureSuppResult> results;

  const FeatureSupportInfoDialog({
    super.key,
    required this.featureSupportScore,
    required this.results,
  });

  @override
  _FeatureSupportInfoDialogState createState() =>
      _FeatureSupportInfoDialogState();
}

class _FeatureSupportInfoDialogState extends State<FeatureSupportInfoDialog> {
  final Set<int> expandedIndexes = {};
  String _statusLabel(FeatureSuppResult feature) {
    if (feature.incompatible) return "Incompatible";

    switch (feature.status) {
      case FeatureStatus.permissionDenied:
        return "Denied";
      case FeatureStatus.serviceDisabled:
        return "Disabled";
      case FeatureStatus.supported:
        return "Supported";
      default:
        return feature.status.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter unsupported features
    final unsupported = widget.results
        .where((r) => r.incompatible || r.status != FeatureStatus.supported)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Feature Support Details",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (unsupported.isNotEmpty)
              SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: unsupported.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final feature = unsupported[index];
                    final isExpanded = expandedIndexes.contains(index);
                    final canExpand =
                        feature.incompatible ||
                        feature.status != FeatureStatus.supported;

                    return GestureDetector(
                      onTap: canExpand
                          ? () {
                              setState(() {
                                if (isExpanded) {
                                  expandedIndexes.remove(index);
                                } else {
                                  expandedIndexes.add(index);
                                }
                              });
                            }
                          : null,
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
                                    feature.stepType.name.toUpperCase(),
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
                                    color: feature.incompatible
                                        ? Colors.red.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusLabel(feature),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: feature.incompatible
                                          ? Colors.red
                                          : feature.status ==
                                                FeatureStatus.permissionDenied
                                          ? Colors.deepOrange
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                                if (canExpand) const SizedBox(width: 8),
                                if (canExpand)
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),

                            // Expanded reason/message
                            if (isExpanded && feature.message != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  feature.message!,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "All required features are supported ✅",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.green),
                ),
              ),

            const SizedBox(height: 16),

            // Overall score
            Row(
              children: [
                Text(
                  "Feature Support Score: ",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  widget.featureSupportScore.overallScore.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
