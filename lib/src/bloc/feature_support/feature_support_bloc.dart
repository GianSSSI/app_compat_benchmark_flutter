import 'dart:collection';

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
    on<StartFeatureSupportCheck>(_onStart);
  }

  Future<void> _onStart(
    StartFeatureSupportCheck event,
    Emitter<FeatureSupportState> emit,
  ) async {
    final results = <FeatureSuppResult>[];

    try {
      for (final step in event.featureRequirements) {
        emit(FeatureSupportChecking(step));

        final res = await _runStep(step);
        results.add(res);
      }

      final score = scorer.calculate(List.unmodifiable(results));

      final hasHardBlocker = results.any(
        (r) => r.incompatible && r.stepType.isHardBlocker,
      );

      emit(
        FeatureSupportScored(
          UnmodifiableListView(results),
          score,
          hasHardBlocker,
        ),
      );
    } catch (e, st) {
      debugPrint("BNCH Error in Feature Support Bloc: $e\n$st");
      emit(FeatureSupportError(e.toString(), FeatureStepType.camera));
    }
  }

  Future<FeatureSuppResult> _runStep(FeatureStepType step) {
    switch (step) {
      case FeatureStepType.camera:
        return runner.checkCamera();

      case FeatureStepType.gps:
        return runner.checkLocation();

      case FeatureStepType.nfc:
        return runner.checkNfc();
    }
  }
}
