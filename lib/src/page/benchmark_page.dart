import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:app_compat_benchmark_flutter/src/api/becnhmark_config_api.dart';
import 'package:app_compat_benchmark_flutter/src/api/dio_client.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/benchmark_config/benchmark_config_cubit.dart';

import 'package:app_compat_benchmark_flutter/src/models/benchmark_handles.dart';
import 'package:app_compat_benchmark_flutter/src/models/benchmark_scorers.dart';
import 'package:app_compat_benchmark_flutter/src/repository/benchmark_config_repository.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/overlays/benchmark_results_overlay.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/progress/circular_progrees.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/progress/linear_progress_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/device_and_os/device_and_os_bloc.dart';
import '../bloc/feature_support/feature_support_bloc.dart';
import '../bloc/internet/internet_bloc.dart';
import '../bloc/main/app_compat_main_bloc.dart';
import '../bloc/performance/performance_bloc.dart';

class BenchmarkPage extends StatefulWidget {
  final String loadingAnimationAsset;
  final String compatibleAnimationAsset;
  final String incompatibleAnimationAsset;

  const BenchmarkPage({
    super.key,
    required this.loadingAnimationAsset,
    required this.compatibleAnimationAsset,
    required this.incompatibleAnimationAsset,
  });

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // build config dependencies here
    final dio = createDioClient();
    final api = BenchmarkConfigApi(dio);
    final repo = BenchmarkConfigRepository(api);

    return BlocProvider(
      create: (_) => BenchmarkConfigCubit(repo)..load(),
      child: BlocBuilder<BenchmarkConfigCubit, BenchmarkConfigState>(
        builder: (context, cfgState) {
          if (cfgState.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (cfgState.error != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Device Benchmark')),
              body: Center(child: Text('Config error: ${cfgState.error}')),
            );
          }

          final cfg = cfgState.config!;
          final scorers = BenchmarkScorers.fromConfig(cfg);

          // Runners
          final benchmarkRunner = BenchmarkRunner();
          final featureRunner = FeatureCheckerRunner();
          final internetRunner = InternetCheckerRunner();
          final deviceRunner = DeviceAndOsRunner();

          // Child blocs
          final deviceBloc = DeviceAndOsBloc(
            runner: deviceRunner,
            deviceAndOsScorer: scorers.deviceAndOsScorer,
          );

          final featureBloc = FeatureSupportBloc(
            runner: featureRunner,
            scorer: scorers.featureSupportScorer,
          );

          final performanceBloc = PerformanceBloc(benchmarkRunner);

          final internetBloc = InternetBloc(internetRunner);

          // Main bloc (migrated)
          final mainBloc = AppCompatMainBloc(
            deviceBloc: deviceBloc,
            featureBloc: featureBloc,
            performanceBloc: performanceBloc,
            internetBloc: internetBloc,

            domainScorer: scorers.domainScorer,
            performanceScorer: scorers.performanceScorer,

            mainDomainScores: cfg.mainDomainScores,
            featureSupportRequirements: cfg.featureSupport,
          );

          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: deviceBloc),
              BlocProvider.value(value: featureBloc),
              BlocProvider.value(value: performanceBloc),
              BlocProvider.value(value: internetBloc),
              BlocProvider.value(value: mainBloc),
            ],
            child: Scaffold(
              appBar: AppBar(title: const Text('Device Benchmark')),
              body: BlocConsumer<AppCompatMainBloc, AppCompatMainState>(
                listener: (context, state) {
                  debugPrint("App Compat STATE CHANGED: ${state.stage}");
                  if (state.stage == BenchmarkStage.error) {
                    debugPrint("BNCH App Compat Main ERROR: ${state.message}");
                  }
                },
                builder: (context, state) {
                  final weights = cfg.mainDomainScores; // ✅ new domain weights

                  bool showList =
                      state.stage == BenchmarkStage.runningPerformance ||
                      state.stage == BenchmarkStage.completed;

                  return Stack(
                    children: [
                      // ListView behind overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: true,
                          child: AnimatedOpacity(
                            opacity: showList ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: 80,
                              itemBuilder: (_, i) => ListTile(
                                title: Text('Sample Item $i'),
                                leading: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.blueAccent,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child: Text(
                                      "$i",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                subtitle: Text("Subtitle $i"),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Idle screen with static metrics
                      if (state.stage == BenchmarkStage.idle)
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SizedBox(
                                  height: 200,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Text(
                                          "Metrics",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text("Device and OS"),
                                                    const SizedBox(height: 8),
                                                    Expanded(
                                                      child: StaticProgressBar(
                                                        progress:
                                                            weights.deviceAndOs,
                                                        text:
                                                            "${(weights.deviceAndOs * 100).toStringAsFixed(0)}%",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            "Performance",
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Expanded(
                                                            child: StaticProgressBar(
                                                              progress: weights
                                                                  .performance,
                                                              text:
                                                                  "${(weights.performance * 100).toStringAsFixed(0)}%",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            "Feature Support",
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Expanded(
                                                            child: StaticProgressBar(
                                                              progress: weights
                                                                  .featureSupport,
                                                              text:
                                                                  "${(weights.featureSupport * 100).toStringAsFixed(0)}%",
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Benchmarking",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Benchmarking will test scrolling, navigation, and animations. Do not close or interact with the app.",
                                        textAlign: TextAlign.justify,
                                      ),
                                      const SizedBox(height: 40),
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            context
                                                .read<AppCompatMainBloc>()
                                                .add(
                                                  StartFullBenchmark(
                                                    handles: BenchmarkHandles(
                                                      scrollController:
                                                          _scrollController,
                                                      context: context,
                                                      tickerProvider: this,
                                                    ),
                                                  ),
                                                );
                                          },
                                          child:
                                              const SpinningBigCircularProgress(
                                                size: 200,
                                                isRunning: false,
                                                text: 'Tap to Start',
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Overlay when running
                      if (state.stage == BenchmarkStage.runningDevice ||
                          state.stage == BenchmarkStage.runningFeatures ||
                          state.stage == BenchmarkStage.runningPerformance ||
                          state.stage == BenchmarkStage.runningInternetCheck)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: const SpinningBigCircularProgress(
                            size: 250,
                            isRunning: true,
                            text: 'Running Benchmark...',
                          ),
                        ),

                      // Completed screen
                      if (state.stage == BenchmarkStage.completed)
                        Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(24),
                          child: SingleChildScrollView(
                            child: BenchmarkResultOverlay(
                              deviceScore: state.deviceScore!,
                              featureScore: state.featureScore!,
                              performanceScore: state.performanceScore!,
                              internetResult: state.internetResult!,
                              overallBenchmarkScore:
                                  state.overallBenchmarkScore!,
                              deviceInformation: state.deviceInfo!,
                              featureResult: state.featureResults!,
                              hasHardBlocker: state.incompatible,
                              loadingAnimationAsset:
                                  widget.loadingAnimationAsset,
                              compatibleAnimationAsset:
                                  widget.compatibleAnimationAsset,
                              incompatibleAnimationAsset:
                                  widget.incompatibleAnimationAsset,

                              // ✅ NEW: pass mainDomainScores for thresholds/colors
                              mainDomainScoresSet: cfg.mainDomainScores,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
