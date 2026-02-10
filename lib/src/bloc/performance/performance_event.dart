part of 'performance_bloc.dart';

abstract class BenchmarkEvent {}

class RunBenchmark extends BenchmarkEvent {
  final ScrollController scrollController;
  final BuildContext context;
  final TickerProvider tickerProvider;

  RunBenchmark({
    required this.scrollController,
    required this.context,
    required this.tickerProvider,
  });
}

class ScoreBenchmark extends BenchmarkEvent {
  final List<BenchmarkStepResult> results;

  ScoreBenchmark({required this.results});
}
