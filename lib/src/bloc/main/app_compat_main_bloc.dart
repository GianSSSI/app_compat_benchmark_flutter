import 'dart:async';

import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/device_and_os/device_and_os_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/feature_support/feature_support_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/internet/internet_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/performance/performance_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/models/benchmark_handles.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'app_compat_main_event.dart';
part 'app_compat_main_state.dart';

class AppCompatMainBloc extends Bloc<AppCompatMainEvent, AppCompatMainState> {
  final DeviceAndOsBloc deviceBloc;
  final FeatureSupportBloc featureBloc;
  final PerformanceBloc performanceBloc;
  final InternetBloc internetBloc;

  final DomainScorer domainScorer;

  final PerformanceRequirementsSet? performanceRequirementsSet;
  final DeviceAndOsRequirementsSet? deviceAndOsRequirementsSet;
  final OverallScoreRequirementsSet? overallScoreRequirementsSet;
  final FeatureSupportRequirementsSet? featureSupportRequirementsSet;
  final DomainWeightsSet? domainWeights;

  late final StreamSubscription deviceSub;
  late final StreamSubscription featureSub;
  late final StreamSubscription performanceSub;
  late final StreamSubscription internetSub;

  BenchmarkHandles? _handles;

  AppCompatMainBloc({
    this.featureSupportRequirementsSet,
    this.deviceAndOsRequirementsSet,
    this.performanceRequirementsSet,
    this.domainWeights,
    this.overallScoreRequirementsSet,
    required this.deviceBloc,
    required this.featureBloc,
    required this.performanceBloc,
    required this.internetBloc,
    required this.domainScorer,
  }) : super(const AppCompatMainState()) {
    on<StartFullBenchmark>(_start);
    on<DeviceAndOsFinished>(_onDeviceDone);
    on<FeatureSupportFinished>(_onFeatureDone);
    on<PerformanceFinished>(_onPerformanceDone);
    on<InternetFinished>(_onInternetDone);
    _listenToChildren();
  }

  OverallScoreRequirementsSet get scoreThresholds =>
      overallScoreRequirementsSet ??
      OverallScoreRequirementsDefaultsBundle.defaults;

  FeatureSupportRequirementsSet get _featSUppRequirements =>
      featureSupportRequirementsSet ??
      FeatureSupportRequirementsDefaultsBundle.defaults;

  void _listenToChildren() {
    deviceSub = deviceBloc.stream.listen((state) {
      debugPrint(
        "BNCH [DeviceBloc] status=${state.status} msg=${state.message}",
      );
      if (state.status == DeviceAndOsStatus.scored) {
        final score = DeviceAndOsDomainScore(
          domainScore: state.deviceAndOSScore ?? 0,
          osScore: state.osScore ?? 0,
          cpuScore: state.cpuScore ?? 0,
          ramStorageScore: state.ramStorageScore ?? 0,
          incompatible: state.incompatible,
          results: state.results,
        );

        add(
          DeviceAndOsFinished(
            score: score,
            incompatible: state.incompatible,
            deviceInformation: state.deviceInfo!,
          ),
        );
      }
    });

    featureSub = featureBloc.stream.listen((state) {
      debugPrint("BNCH [featureBloc] status=${state}");
      if (state is FeatureSupportScored) {
        add(
          FeatureSupportFinished(
            score: state.score,
            feautreSupportResults: state.results,
          ),
        );
      }
    });

    performanceSub = performanceBloc.stream.listen((state) {
      debugPrint("BNCH [performanceBloc] status=${state}");
      if (state is BenchmarkCompleted) {
        final scorer = BenchmarkScorer();
        final stepScores = state.results.map(scorer.scoreStep).toList();
        final overall = scorer.scoreOverall(state.results);

        final score = PerformanceDomainScore(
          stepScores: stepScores,
          overallScore: overall,
          overallRating: overall.rating,
          results: state.results,
        );

        add(PerformanceFinished(score));
      }
    });

    internetSub = internetBloc.stream.listen((state) {
      if (state is InternetCheckSuccess) {
        add(InternetFinished(state.result));
      }
    });
  }

  void _start(StartFullBenchmark event, Emitter<AppCompatMainState> emit) {
    _handles = event.handles;
    emit(state.copyWith(stage: BenchmarkStage.runningDevice));
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
        incompatible: event.incompatible, // mark if device has issues
        message: event.incompatible ? "Device not fully compatible" : null,
      ),
    );

    featureBloc.add(
      StartFeatureSupportCheck(
        featureRequirements: _featSUppRequirements.requiredFeatures.value.keys
            .toList(),
      ),
    );
  }

  void _onFeatureDone(
    FeatureSupportFinished event,
    Emitter<AppCompatMainState> emit,
  ) {
    if (event.incompatible) {
      emit(
        state.copyWith(
          stage: BenchmarkStage.incompatible,
          incompatible: true,
          message: "Required features are not supported on this device",
          featureResults: event.feautreSupportResults,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        featureScore: event.score,
        stage: BenchmarkStage.runningPerformance,
        featureResults: event.feautreSupportResults,
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
  Future<void> close() {
    deviceSub.cancel();
    featureSub.cancel();
    performanceSub.cancel();
    return super.close();
  }
}
