part of 'app_compat_main_bloc.dart';

enum BenchmarkStage {
  idle,
  runningDevice,
  runningFeatures,
  runningPerformance,
  runningInternetCheck,
  completed,
  incompatible,
  error,
}

class AppCompatMainState extends Equatable {
  final BenchmarkStage stage;

  final DeviceAndOsDomainScore? deviceScore;
  final FeatureSupportScore? featureScore;
  final PerformanceDomainScore? performanceScore;
  final InternetCheckResult? internetResult;

  final List<FeatureSuppResult>? featureResults;
  final DeviceInformation? deviceInfo;

  final OverallBenchmarkScore? overallBenchmarkScore;

  final String? message;
  final bool incompatible;

  final String? errorMessage;
  final String? errorStackTrace;
  final BenchmarkStage? failedStage;

  const AppCompatMainState({
    this.stage = BenchmarkStage.idle,
    this.deviceScore,
    this.featureScore,
    this.performanceScore,
    this.overallBenchmarkScore,
    this.message,
    this.internetResult,
    this.deviceInfo,
    this.incompatible = false,
    this.featureResults,
    this.errorMessage,
    this.errorStackTrace,
    this.failedStage,
  });

  AppCompatMainState copyWith({
    BenchmarkStage? stage,
    DeviceAndOsDomainScore? deviceScore,
    FeatureSupportScore? featureScore,
    PerformanceDomainScore? performanceScore,
    InternetCheckResult? internetResult,
    DeviceInformation? deviceInfo,
    List<FeatureSuppResult>? featureResults,
    OverallBenchmarkScore? overallBenchmarkScore,
    String? message,
    bool? incompatible,
    String? errorMessage,
    String? errorStackTrace,
    BenchmarkStage? failedStage,
  }) {
    return AppCompatMainState(
      stage: stage ?? this.stage,
      deviceScore: deviceScore ?? this.deviceScore,
      featureScore: featureScore ?? this.featureScore,
      performanceScore: performanceScore ?? this.performanceScore,
      internetResult: internetResult ?? this.internetResult,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      featureResults: featureResults ?? this.featureResults,
      overallBenchmarkScore:
          overallBenchmarkScore ?? this.overallBenchmarkScore,
      message: message ?? this.message,
      incompatible: incompatible ?? this.incompatible,
      errorMessage: errorMessage ?? this.errorMessage,
      errorStackTrace: errorStackTrace ?? this.errorStackTrace,
      failedStage: failedStage ?? this.failedStage,
    );
  }

  AppCompatMainState cleared() =>
      const AppCompatMainState(stage: BenchmarkStage.idle);
  @override
  List<Object?> get props => [
    stage,
    deviceScore,
    featureScore,
    performanceScore,
    internetResult,
    featureResults,
    deviceInfo,
    overallBenchmarkScore,
    message,
    incompatible,
  ];
}
