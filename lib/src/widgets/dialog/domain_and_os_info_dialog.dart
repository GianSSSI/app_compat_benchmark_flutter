import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:flutter/material.dart';

class DomainAndOsInfoDialog extends StatefulWidget {
  final DeviceAndOsDomainScore deviceScore;
  final DeviceInformation deviceInformation;

  const DomainAndOsInfoDialog({
    super.key,
    required this.deviceScore,
    required this.deviceInformation,
  });

  @override
  _DomainAndOsInfoDialogState createState() => _DomainAndOsInfoDialogState();
}

class _DomainAndOsInfoDialogState extends State<DomainAndOsInfoDialog> {
  final Set<int> expandedIndexes = {};
  @override
  Widget build(BuildContext context) {
    // Unsupported features
    final unsupported = widget.deviceScore.results.toList();

    // Build the list of all rows: OS, CPU, RAM & Storage, plus unsupported
    final List<_ExpandableRow> rows = [
      _ExpandableRow(
        title: "OS Version",
        score: widget.deviceScore.osScore,
        content:
            "${widget.deviceInformation.operatingSystem} ${widget.deviceInformation.systemVersion}",
      ),
      _ExpandableRow(
        title: "CPU",
        score: widget.deviceScore.cpuScore,
        content:
            "Arch: ${widget.deviceInformation.cpuArchitecture}\n"
            "Cores: ${widget.deviceInformation.cpuCores}\n"
            "Freq: ${widget.deviceInformation.cpuFrequencyMhz}",
      ),
      _ExpandableRow(
        title: "RAM & Storage",
        score: widget.deviceScore.ramStorageScore,
        content:
            "RAM: ${widget.deviceInformation.availableRamMb.toStringAsFixed(0)} MB\n"
            "Storage: ${widget.deviceInformation.availableMemoryMb.toStringAsFixed(0)} GB",
      ),
      // Add unsupported results **except OS Version**, because it already has its own row
      ...unsupported
          .where((f) => f.type.name != "osVersion")
          .map(
            (f) => _ExpandableRow(
              title: f.type.name.toUpperCase(),
              score: null,
              content: f.message,
            ),
          ),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Device & OS Details",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 400,
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
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
                          // Title row with optional score
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  row.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (row.score != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: row.score == -1
                                        ? Colors.red.shade100
                                        : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    row.score! == -1
                                        ? "INC"
                                        : row.score!.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: row.score! == -1
                                          ? Colors.red
                                          : Colors.blue,
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

                          // Expanded details
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: row.score == -1
                                  ? Text(
                                      "Does not meet the app's minimum requirements",
                                    )
                                  : Text(
                                      row.content,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
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
                  "Device & OS Score: ",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  widget.deviceScore.domainScore.toStringAsFixed(2),
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

class _ExpandableRow {
  final String title;
  final double? score;
  final String content;

  _ExpandableRow({required this.title, this.score, required this.content});
}
