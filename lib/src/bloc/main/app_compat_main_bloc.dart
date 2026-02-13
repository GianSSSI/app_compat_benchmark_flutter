import 'dart:async';

import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/device_and_os/device_and_os_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/feature_support/feature_support_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/internet/internet_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/performance/performance_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/helpers/required_steps.dart';
import 'package:app_compat_benchmark_flutter/src/models/benchmark_handles.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'app_compat_main_event.dart';
part 'app_compat_main_state.dart';

class AppCompatMainBloc extends Bloc<AppCompatMainEvent, AppCompatMainState> {
  final DeviceAndOsBloc deviceBloc;
  final FeatureSupportBloc featureBloc;
  final PerformanceBloc performanceBloc;
  final InternetBloc internetBloc;

  // NEW: built from config
  final DomainScorer domainScorer;
  final BenchmarkScorer performanceScorer;

  // NEW: config sets (merged remote+defaults)
  final MainDomainScoresSet mainDomainScores;
  final FeatureSupportRequirementsSet featureSupportRequirements;

  late final StreamSubscription deviceSub;
  late final StreamSubscription featureSub;
  late final StreamSubscription performanceSub;
  late final StreamSubscription internetSub;

  BenchmarkHandles? _handles;

  AppCompatMainBloc({
    required this.deviceBloc,
    required this.featureBloc,
    required this.performanceBloc,
    required this.internetBloc,

    required this.domainScorer,
    required this.performanceScorer,

    required this.mainDomainScores,
    required this.featureSupportRequirements,
  }) : super(const AppCompatMainState()) {
    on<StartFullBenchmark>(_start);
    on<DeviceAndOsFinished>(_onDeviceDone);
    on<FeatureSupportFinished>(_onFeatureDone);
    on<PerformanceFinished>(_onPerformanceDone);
    on<InternetFinished>(_onInternetDone);

    _listenToChildren();
  }

  void _listenToChildren() {
    deviceSub = deviceBloc.stream.listen((s) {
      debugPrint("BNCH [DeviceBloc] status=${s.status} msg=${s.message}");
      if (s.status == DeviceAndOsStatus.scored) {
        final score = DeviceAndOsDomainScore(
          domainScore: s.deviceAndOSScore ?? 0,
          osScore: s.osScore ?? 0,
          cpuScore: s.cpuScore ?? 0,
          ramStorageScore: s.ramStorageScore ?? 0,
          incompatible: s.incompatible,
          results: s.results,
        );

        add(
          DeviceAndOsFinished(
            score: score,
            incompatible: s.incompatible,
            deviceInformation: s.deviceInfo!,
          ),
        );
      }
    });

    featureSub = featureBloc.stream.listen((s) {
      debugPrint("BNCH [featureBloc] state=$s");
      if (s is FeatureSupportScored) {
        add(
          FeatureSupportFinished(
            score: s.score,
            feautreSupportResults: s.results,
            incompatible: s.score.isBlocked, // ✅ use scorer decision
          ),
        );
      }
    });

    performanceSub = performanceBloc.stream.listen((s) {
      debugPrint("BNCH [performanceBloc] state=$s");
      if (s is BenchmarkCompleted) {
        // ✅ Use injected performanceScorer (config-based)
        final stepScores = s.results.map(performanceScorer.scoreStep).toList();
        final overall = performanceScorer.scoreOverall(s.results);

        final score = PerformanceDomainScore(
          stepScores: stepScores,
          overallScore: overall,
          overallRating: overall.rating,
          results: s.results,
        );

        add(PerformanceFinished(score));
      }
    });

    internetSub = internetBloc.stream.listen((s) {
      if (s is InternetCheckSuccess) {
        add(InternetFinished(s.result));
      }
    });
  }

  void _start(StartFullBenchmark event, Emitter<AppCompatMainState> emit) {
    _handles = event.handles;
    emit(state.copyWith(stage: BenchmarkStage.runningDevice, message: null));
    deviceBloc.add(GetDeviceInformation());
  }

  void _onDeviceDone(
    DeviceAndOsFinished event,
    Emitter<AppCompatMainState> emit,
  ) {
    emit(
      state.copyWith(
        deviceScore: event.score,
        deviceInfo: event.deviceInformation,
        stage: BenchmarkStage.runningFeatures,
        incompatible: event.incompatible,
        message: event.incompatible ? "Device not fully compatible" : null,
      ),
    );

    // ✅ NEW: use typed RequiredFeatures -> steps list
    final requiredSteps = requiredStepsFromConfig(
      featureSupportRequirements.requiredFeatures,
    );

    featureBloc.add(
      StartFeatureSupportCheck(featureRequirements: requiredSteps),
    );
  }

  void _onFeatureDone(
    FeatureSupportFinished event,
    Emitter<AppCompatMainState> emit,
  ) {
    // ✅ DO NOT STOP — just record blocker and proceed
    final blocked = event.incompatible;

    emit(
      state.copyWith(
        featureScore: event.score,
        featureResults: event.feautreSupportResults,
        incompatible: state.incompatible || blocked, // accumulate blockers
        message: blocked
            ? "Some required features are not supported (continuing benchmark)"
            : state.message,
        stage: BenchmarkStage.runningPerformance,
      ),
    );

    performanceBloc.add(
      RunBenchmark(
        scrollController: _handles!.scrollController,
        context: _handles!.context,
        tickerProvider: _handles!.tickerProvider,
      ),
    );
  }

  void _onPerformanceDone(
    PerformanceFinished event,
    Emitter<AppCompatMainState> emit,
  ) {
    final finalScore = domainScorer.calculateFinalScore(
      device: state.deviceScore!.domainScore,
      feature: state.featureScore!,
      performance: event.score,
    );

    emit(
      state.copyWith(
        performanceScore: event.score,
        overallBenchmarkScore: finalScore,
        stage: BenchmarkStage.runningInternetCheck,
      ),
    );

    internetBloc.add(CheckInternetConnection());
  }

  void _onInternetDone(
    InternetFinished event,
    Emitter<AppCompatMainState> emit,
  ) {
    emit(
      state.copyWith(
        internetResult: event.result,
        stage: BenchmarkStage.completed,
      ),
    );
  }

  @override
  Future<void> close() async {
    await deviceSub.cancel();
    await featureSub.cancel();
    await performanceSub.cancel();
    await internetSub.cancel();
    return super.close();
  }
}
