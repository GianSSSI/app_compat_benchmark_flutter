// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'performance_bloc.dart';

abstract class PerformanceState {}

class BenchmarkIdle extends PerformanceState {}

class BenchmarkRunning extends PerformanceState {
  final BenchmarkStepType currentStep;
  BenchmarkRunning(this.currentStep);
}

class BenchmarkCompleted extends PerformanceState {
  final List<BenchmarkStepResult> results;
  BenchmarkCompleted(this.results);
}

class BenchmarkError extends PerformanceState {
  final String message;
  BenchmarkError(this.message);
}

class BenchmarkScored extends PerformanceState {
  List<BenchmarkStepScore> stepScores;
  List<BenchmarkStepResult> results;
  double overallScore;
  String overallRating;
  BenchmarkScored({
    required this.results,
    required this.stepScores,
    required this.overallScore,
    required this.overallRating,
  });
}
