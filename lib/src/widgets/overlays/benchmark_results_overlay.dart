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

  // ✅ NEW: overall thresholds now come from mainDomainScores.thresholds
  final MainDomainScoresSet? mainDomainScoresSet;

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
    this.mainDomainScoresSet,
  });

  @override
  State<BenchmarkResultOverlay> createState() => _BenchmarkResultOverlayState();

  // ✅ fallback to defaults (new system)
  MainDomainScoresSet get main =>
      mainDomainScoresSet ?? MainDomainScoresDefaults();
}

class _BenchmarkResultOverlayState extends State<BenchmarkResultOverlay>
    with TickerProviderStateMixin {
  final List<bool> _visible = [false, false, false, false, false];
  bool _internetCardVisible = false;

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
      builder: (_) => DomainAndOsInfoDialog(
        deviceInformation: widget.deviceInformation,
        deviceScore: widget.deviceScore,
      ),
    );
  }

  void _showFeatureSupportInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => FeatureSupportInfoDialog(
        featureSupportScore: widget.featureScore,
        results: widget.featureResult,
      ),
    );
  }

  void _showPerformanceInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => PerformanceInfoDialog(
        performanceDomainScore: widget.performanceScore,
      ),
    );
  }

  void _showOverallInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => OverallInfoDialog(
        overallBenchmarkScore: widget.overallBenchmarkScore,
      ),
    );
  }

  void _runAnimations() {
    for (int i = 0; i < _visible.length; i++) {
      Timer(Duration(milliseconds: 500 * i), () {
        if (!mounted) return;

        setState(() {
          _visible[i] = true;

          if (i == _visible.length - 1) {
            _currentAnimation = widget.hasHardBlocker
                ? widget.incompatibleAnimationAsset
                : widget.compatibleAnimationAsset;

            Timer(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              setState(() => _internetCardVisible = true);
            });
          }
        });
      });
    }
  }

  Color getScoreColor(double score) {
    final t = widget.main.thresholds; // TieredReq

    if (score >= t.optimal) {
      return Colors.lightGreen.shade300; // optimal
    }
    if (score >= t.supported) {
      return Colors.amber.shade300; // supported
    }
    if (score >= t.limited) {
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
        onTap: _showDomainAndOsInfoDialog,
      ),
      DomainResultCard(
        title: 'Feature Support Score',
        score: widget.featureScore.overallScore.toStringAsFixed(2),
        backgroundColor: getScoreColor(widget.featureScore.overallScore),
        onTap: _showFeatureSupportInfoDialog,
        incompatible: widget.featureScore.isBlocked,
      ),
      DomainResultCard(
        title: 'Performance Score',
        score: widget.performanceScore.overallScore.toStringAsFixed(2),
        backgroundColor: getScoreColor(widget.performanceScore.overallScore),
        onTap: _showPerformanceInfoDialog,
      ),
      DomainResultCard(
        isOverallScore: true,
        title: "Overall Score",
        score: widget.overallBenchmarkScore.score.toStringAsFixed(2),
        incompatible: widget.hasHardBlocker,
        onTap: _showOverallInfoDialog,
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
          const Divider(height: 30, thickness: 1.5),

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
                        const Spacer(),
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
