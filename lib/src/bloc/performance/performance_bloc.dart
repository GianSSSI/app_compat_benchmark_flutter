import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'performance_event.dart';
part 'performance_state.dart';

class PerformanceBloc extends Bloc<BenchmarkEvent, PerformanceState> {
  final BenchmarkRunner runner;

  PerformanceBloc(this.runner) : super(BenchmarkIdle()) {
    on<RunBenchmark>(_onRunBenchmark);
    on<ScoreBenchmark>(_scoreBenchmark);
  }

  Future<void> _onRunBenchmark(
    RunBenchmark event,
    Emitter<PerformanceState> emit,
  ) async {
    try {
      final results = <BenchmarkStepResult>[];

      // Idle
      emit(BenchmarkRunning(BenchmarkStepType.idle));
      results.add(
        await runner.runStep(
          step: BenchmarkStepType.idle,
          action: () async => Future.delayed(const Duration(seconds: 2)),
        ),
      );

      // Scroll
      emit(BenchmarkRunning(BenchmarkStepType.scroll));
      results.add(
        await runner.runStep(
          step: BenchmarkStepType.scroll,
          action: () => runner.scrollTest(event.scrollController),
        ),
      );

      // Navigation
      emit(BenchmarkRunning(BenchmarkStepType.navigation));
      results.add(
        await runner.runStep(
          step: BenchmarkStepType.navigation,
          action: () => runner.navigationTest(event.context),
        ),
      );

      // Animation
      emit(BenchmarkRunning(BenchmarkStepType.animation));
      results.add(
        await runner.runStep(
          step: BenchmarkStepType.animation,
          action: () =>
              runner.animationStressTest(event.context, event.tickerProvider),
        ),
      );

      emit(BenchmarkCompleted(List.from(results)));
    } catch (e) {
      emit(BenchmarkError(e.toString()));
    }
  }

  Future<void> _scoreBenchmark(
    ScoreBenchmark event,
    Emitter<PerformanceState> emit,
  ) async {
    if (state is! BenchmarkCompleted) return;

    final results = (state as BenchmarkCompleted).results;
    final scorer = BenchmarkScorer();

    // Score each step
    final stepScores = results.map(scorer.scoreStep).toList();

    // Overall score
    final overall = scorer.scoreOverall(results);
    final overallRating = overall.rating;

    emit(
      BenchmarkScored(
        stepScores: stepScores,
        overallScore: overall,
        overallRating: overallRating,
        results: results,
      ),
    );
  }
}
