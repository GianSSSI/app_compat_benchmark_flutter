import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'feature_support_event.dart';
part 'feature_support_state.dart';

class FeatureSupportBloc
    extends Bloc<FeatureSupportEvent, FeatureSupportState> {
  final FeatureCheckerRunner runner;
  final FeatureSupportScorer scorer;
  FeatureSupportBloc({required this.runner, required this.scorer})
    : super(FeatureSupportInitial()) {
    on<StartFeatureSupportCheck>((event, emit) async {
      List<FeatureSuppResult> results = [];
      for (final feature in event.featureRequirements) {
        try {
          switch (feature) {
            case FeatureStepType.camera:
              final featureResult = await runner.checkCamera();

              results.add(featureResult);
              break;
            case FeatureStepType.gps:
              final featureResult = await runner.checkLocation();

              if (featureResult.incompatible) {
                emit(
                  FeatureSupportComplete(
                    results: results,
                    hasHardBlocker: true,
                  ),
                );
              }
              results.add(featureResult);
              break;
          }
        } catch (e) {
          debugPrint("Error in Feature Support Bloc: $e");
        }
      }
      emit(FeatureSupportComplete(results: results));
      add(ScoreFeatureSupport(results));
    });

    on<ScoreFeatureSupport>((event, emit) {
      final score = scorer.calculate(event.results);

      final hasHardBlocker = event.results.any((r) => r.incompatible);

      emit(FeatureSupportScored(event.results, score, hasHardBlocker));
    });

    // on<StartFeatureSupportCheck>((event, emit) async {
    //   Map<FeatureStepType, FeatureCheckResult> results = {};
    //   for (final feature in event.featureRequirements) {
    //     try {
    //       switch (feature) {
    //         case FeatureStepType.camera:
    //           results[feature] = await runner.checkCamera();
    //           break;
    //         case FeatureStepType.gps:
    //           results[feature] = await runner.checkLocation();
    //           break;
    //       }

    //       MyLogger.d("Event Feature Check Result: $results");
    //     } catch (e) {
    //       MyLogger.e('Feature check error: $e');
    //     }
    //   }
    //   emit(FeatureSupportComplete(results));
    //   add(ScoreFeatureSupport(results));
    // });

    // on<ScoreFeatureSupport>((event, emit) {
    //   final score = FeatureSupportScorer.calculate(event.results);

    //   MyLogger.d(
    //     'Feature Support Score: ${score.overallScore.toStringAsFixed(1)}%',
    //   );

    //   emit(FeatureSupportScored(event.results, score));
    // });
  }
}
