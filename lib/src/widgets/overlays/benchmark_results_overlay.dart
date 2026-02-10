import 'dart:async';
import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/dialog/domain_and_os_info_dialog.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/dialog/feature_support_info_dialog.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/dialog/overall_info_dialog.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/dialog/performance_info_dailog.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/domain_result_card.dart';
import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';

class BenchmarkResultOverlay extends StatefulWidget {
  final String loadingAnimationAsset;
  final String compatibleAnimationAsset;
  final String incompatibleAnimationAsset;
  final DeviceAndOsDomainScore deviceScore;
  final DeviceInformation deviceInformation;
  final List<FeatureSuppResult> featureResult;
  final FeatureSupportScore featureScore;
  final PerformanceDomainScore performanceScore;
  final InternetCheckResult internetResult;
  final OverallBenchmarkScore overallBenchmarkScore;
  final bool hasHardBlocker;

  final OverallScoreRequirementsSet? overallScoreRequirementsSet;
  const BenchmarkResultOverlay({
    super.key,
    required this.deviceScore,
    required this.featureScore,
    required this.performanceScore,
    required this.internetResult,
    required this.overallBenchmarkScore,
    required this.deviceInformation,
    required this.featureResult,
    required this.loadingAnimationAsset,
    required this.compatibleAnimationAsset,
    required this.incompatibleAnimationAsset,
    this.hasHardBlocker = false,
    this.overallScoreRequirementsSet,
  });

  @override
  State<BenchmarkResultOverlay> createState() => _BenchmarkResultOverlayState();

  OverallScoreRequirementsSet get scoreThresholds =>
      overallScoreRequirementsSet ??
      OverallScoreRequirementsDefaultsBundle.defaults;
}

class _BenchmarkResultOverlayState extends State<BenchmarkResultOverlay>
    with TickerProviderStateMixin {
  final List<bool> _visible = [
    false,
    false,
    false,
    false,
    false,
  ]; // DomainResultCards
  bool _internetCardVisible = false; // Internet Speed card
  //assets/animations/loading_results.json

  late String _currentAnimation;

  @override
  void initState() {
    super.initState();
    _currentAnimation = widget.loadingAnimationAsset;
    _runAnimations();
  }

  void _showDomainAndOsInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return DomainAndOsInfoDialog(
          deviceInformation: widget.deviceInformation,
          deviceScore: widget.deviceScore,
        );
      },
    );
  }

  void _showFeatureSupportInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return FeatureSupportInfoDialog(
          featureSupportScore: widget.featureScore,
          results: widget.featureResult,
        );
      },
    );
  }

  void _showPerformanceInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return PerformanceInfoDialog(
          performanceDomainScore: widget.performanceScore,
        );
      },
    );
  }

  void _showOverallInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return OverallInfoDialog(
          overallBenchmarkScore: widget.overallBenchmarkScore,
        );
      },
    );
  }

  void _runAnimations() {
    // Fade in
    for (int i = 0; i < _visible.length; i++) {
      Timer(Duration(milliseconds: 500 * i), () {
        if (mounted) {
          setState(() {
            _visible[i] = true;
            // ? 'assets/animations/result_invalid.json'
            //     : 'assets/animations/result_success.json';
            if (i == _visible.length - 1) {
              _currentAnimation = widget.hasHardBlocker
                  ? widget.incompatibleAnimationAsset
                  : widget.compatibleAnimationAsset;

              // Delay 500ms then show Internet Speed card
              Timer(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _internetCardVisible = true;
                  });
                }
              });
            }
          });
        }
      });
    }
  }

  Color getScoreColor(double score) {
    if (score >= widget.scoreThresholds.optimalOverall.value) {
      return Colors.lightGreen.shade300; // optimal
    }
    if (score >= widget.scoreThresholds.supportedOverall.value) {
      return Colors.amber.shade300; // supported
    }
    if (score >= widget.scoreThresholds.limitedOverall.value) {
      return Colors.orange.shade300; // limited
    }
    return Colors.redAccent.shade100; // incompatible
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      DomainResultCard(
        title: 'Device & OS Score',
        score: widget.deviceScore.domainScore.toStringAsFixed(2),
        incompatible: widget.deviceScore.incompatible,
        backgroundColor: getScoreColor(widget.deviceScore.domainScore),
        onTap: () => _showDomainAndOsInfoDialog(),
      ),

      DomainResultCard(
        title: 'Feature Support Score',
        score: widget.featureScore.overallScore.toStringAsFixed(2),
        backgroundColor: getScoreColor(widget.featureScore.overallScore),
        onTap: () => _showFeatureSupportInfoDialog(),
        incompatible: widget.featureScore.isBlocked,
      ),
      DomainResultCard(
        title: 'Performance Score',
        score: widget.performanceScore.overallScore.toStringAsFixed(2),
        backgroundColor: getScoreColor(widget.performanceScore.overallScore),
        onTap: () => _showPerformanceInfoDialog(),
      ),

      DomainResultCard(
        isOverallScore: true,
        title: "Overall Score",
        score: widget.overallBenchmarkScore.score.toStringAsFixed(2),
        incompatible: widget.hasHardBlocker,
        onTap: () => _showOverallInfoDialog(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Lottie.asset(
              _currentAnimation,
              key: ValueKey(_currentAnimation),
              width: 100,
              height: 100,
              fit: BoxFit.fill,
              repeat: _currentAnimation.contains('loading'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.hasHardBlocker
                ? "Device Incompatible"
                : "Device Compatible!",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          // Animated DomainResultCards
          for (int i = 0; i < cards.length; i++)
            AnimatedOpacity(
              opacity: _visible[i] ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeIn,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: cards[i],
              ),
            ),

          const SizedBox(height: 20),

          // Divider
          Divider(height: 30, thickness: 1.5),

          // Internet Speed Card with fade-in
          AnimatedOpacity(
            opacity: _internetCardVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeIn,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Internet Speed",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Download Speed: ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Spacer(),
                        Text(
                          "${widget.internetResult.downloadSpeedMbps.toStringAsFixed(2)} Mbps",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
