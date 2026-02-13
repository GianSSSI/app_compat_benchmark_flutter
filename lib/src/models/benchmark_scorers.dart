// lib/src/di/benchmark_factory.dart
import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';

class BenchmarkScorers {
  final DeviceAndOsScorer deviceAndOsScorer;
  final FeatureSupportScorer featureSupportScorer;
  final BenchmarkScorer performanceScorer;
  final DomainScorer domainScorer;

  BenchmarkScorers({
    required this.deviceAndOsScorer,
    required this.featureSupportScorer,
    required this.performanceScorer,
    required this.domainScorer,
  });

  factory BenchmarkScorers.fromConfig(BenchmarkConfig cfg) {
    final deviceAndOsScorer = DeviceAndOsScorer(
      deviceAndOsRequirementsSet: cfg.deviceAndOs,
      deviceAndOsWeightsSet: cfg.deviceAndOs,
      // scores set is app-only default (optional)
    );

    final featureSupportScorer = FeatureSupportScorer(
      featureSupportRequirementsSet: cfg.featureSupport,
      featureSupportWeightsSet: cfg.featureSupport,
      // score set app-only default (optional)
    );

    final performanceScorer = BenchmarkScorer(
      performanceRequirements: cfg.performance,
      performanceWeights: cfg.performance,
      // performanceScore app-only default (optional)
    );

    final domainScorer = DomainScorer(
      mainDomainScoresSet: cfg.mainDomainScores,
      deviceAndOsRequirementsSet: cfg.deviceAndOs,
      performanceRequirementsSet: cfg.performance,
      featureSupportRequirementsSet: cfg.featureSupport,
    );

    return BenchmarkScorers(
      deviceAndOsScorer: deviceAndOsScorer,
      featureSupportScorer: featureSupportScorer,
      performanceScorer: performanceScorer,
      domainScorer: domainScorer,
    );
  }
}
