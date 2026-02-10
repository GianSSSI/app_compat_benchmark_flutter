part of 'app_compat_main_bloc.dart';

sealed class AppCompatMainEvent extends Equatable {
  const AppCompatMainEvent();

  @override
  List<Object> get props => [];
}

class StartFullBenchmark extends AppCompatMainEvent {
  final BenchmarkHandles handles;

  const StartFullBenchmark({required this.handles});
}

class DeviceAndOsFinished extends AppCompatMainEvent {
  final DeviceAndOsDomainScore score;
  final DeviceInformation deviceInformation;
  final bool incompatible;
  const DeviceAndOsFinished({
    required this.score,
    required this.incompatible,
    required this.deviceInformation,
  });
}

class FeatureSupportFinished extends AppCompatMainEvent {
  final FeatureSupportScore score;
  final List<FeatureSuppResult> feautreSupportResults;
  final bool incompatible;
  const FeatureSupportFinished({
    required this.score,
    required this.feautreSupportResults,
    this.incompatible = false,
  });
}

class PerformanceFinished extends AppCompatMainEvent {
  final PerformanceDomainScore score;

  const PerformanceFinished(this.score);
}

class InternetFinished extends AppCompatMainEvent {
  final InternetCheckResult result;
  const InternetFinished(this.result);
}
