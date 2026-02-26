// benchmark_page.dart
import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:app_compat_benchmark_flutter/src/api/becnhmark_config_api.dart';
import 'package:app_compat_benchmark_flutter/src/api/dio_client.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/benchmark_config/benchmark_config_cubit.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/device_and_os/device_and_os_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/feature_support/feature_support_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/internet/internet_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/main/app_compat_main_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/bloc/performance/performance_bloc.dart';
import 'package:app_compat_benchmark_flutter/src/models/benchmark_handles.dart';
import 'package:app_compat_benchmark_flutter/src/models/benchmark_scorers.dart';
import 'package:app_compat_benchmark_flutter/src/repository/benchmark_config_repository.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/overlays/benchmark_results_overlay.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/progress/circular_progrees.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/progress/linear_progress_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BenchmarkPage extends StatelessWidget {
  final String loadingAnimationAsset;
  final String compatibleAnimationAsset;
  final String incompatibleAnimationAsset;
  final String limitedAnimationAsset;

  final String configUrl;
  const BenchmarkPage({
    super.key,
    required this.limitedAnimationAsset,
    required this.loadingAnimationAsset,
    required this.compatibleAnimationAsset,
    required this.incompatibleAnimationAsset,
    required this.configUrl,
  });

  @override
  Widget build(BuildContext context) {
    final dio = createDioClient();
    final api = BenchmarkConfigApi(dio: dio, baseUrl: configUrl);
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
          return _BenchmarkFlow(
            cfg: cfg,
            loadingAnimationAsset: loadingAnimationAsset,
            compatibleAnimationAsset: compatibleAnimationAsset,
            incompatibleAnimationAsset: incompatibleAnimationAsset,
            limitedAnimationAsset: limitedAnimationAsset,
          );
        },
      ),
    );
  }
}

/// Owns the benchmarking blocs lifecycle (created ONCE in initState).
class _BenchmarkFlow extends StatefulWidget {
  final BenchmarkConfig cfg;
  final String loadingAnimationAsset;
  final String compatibleAnimationAsset;
  final String incompatibleAnimationAsset;
  final String limitedAnimationAsset;

  const _BenchmarkFlow({
    required this.cfg,
    required this.limitedAnimationAsset,
    required this.loadingAnimationAsset,
    required this.compatibleAnimationAsset,
    required this.incompatibleAnimationAsset,
  });

  @override
  State<_BenchmarkFlow> createState() => _BenchmarkFlowState();
}

class _BenchmarkFlowState extends State<_BenchmarkFlow>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late final DeviceAndOsBloc _deviceBloc;
  late final FeatureSupportBloc _featureBloc;
  late final PerformanceBloc _performanceBloc;
  late final InternetBloc _internetBloc;
  late final AppCompatMainBloc _mainBloc;

  late final BenchmarkScorers _scorers;

  @override
  void initState() {
    super.initState();

    // scorers built from config
    _scorers = BenchmarkScorers.fromConfig(widget.cfg);

    // runners (plugin-backed, per app)
    final benchmarkRunner = BenchmarkRunner();
    final featureRunner = FeatureCheckerRunner();
    final internetRunner = InternetCheckerRunner();
    final deviceRunner = DeviceAndOsRunner();

    // child blocs (created once)
    _deviceBloc = DeviceAndOsBloc(
      runner: deviceRunner,
      deviceAndOsScorer: _scorers.deviceAndOsScorer,
    );

    _featureBloc = FeatureSupportBloc(
      runner: featureRunner,
      scorer: _scorers.featureSupportScorer,
    );

    _performanceBloc = PerformanceBloc(benchmarkRunner);
    _internetBloc = InternetBloc(internetRunner);

    // main bloc (created once)
    _mainBloc = AppCompatMainBloc(
      deviceBloc: _deviceBloc,
      featureBloc: _featureBloc,
      performanceBloc: _performanceBloc,
      internetBloc: _internetBloc,
      domainScorer: _scorers.domainScorer,
      performanceScorer: _scorers.performanceScorer,
      mainDomainScores: widget.cfg.mainDomainScores,
      featureSupportRequirements: widget.cfg.featureSupport,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();

    // close main first (it owns subscriptions)
    _mainBloc.close();
    _deviceBloc.close();
    _featureBloc.close();
    _performanceBloc.close();
    _internetBloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weights = widget.cfg.mainDomainScores;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _deviceBloc),
        BlocProvider.value(value: _featureBloc),
        BlocProvider.value(value: _performanceBloc),
        BlocProvider.value(value: _internetBloc),
        BlocProvider.value(value: _mainBloc),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Device Benchmark')),
        body: BlocConsumer<AppCompatMainBloc, AppCompatMainState>(
          listener: (context, state) async {
            if (state.stage == BenchmarkStage.error &&
                state.errorMessage != null) {
              final action = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text('Benchmark error'),
                  content: SingleChildScrollView(
                    child: Text(
                      [
                        state.errorMessage,
                        if (state.failedStage != null)
                          'Stage: ${state.failedStage}',
                      ].whereType<String>().join('\n'),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'cancel'),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'restart'),
                      child: const Text('Restart'),
                    ),
                  ],
                ),
              );

              if (!context.mounted) return;

              if (action == 'cancel') {
                context.read<AppCompatMainBloc>().add(const CancelBenchmark());
              } else if (action == 'restart') {
                context.read<AppCompatMainBloc>().add(const RestartBenchmark());
              }
            }
          },
          builder: (context, state) {
            final showList =
                state.stage == BenchmarkStage.runningPerformance ||
                state.stage == BenchmarkStage.completed;

            return Stack(
              children: [
                // list behind overlay
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

                // idle screen
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                                  progress: weights.deviceAndOs,
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text("Performance"),
                                                    const SizedBox(height: 8),
                                                    Expanded(
                                                      child: StaticProgressBar(
                                                        progress:
                                                            weights.performance,
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "Feature Support",
                                                    ),
                                                    const SizedBox(height: 8),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      context.read<AppCompatMainBloc>().add(
                                        StartFullBenchmark(
                                          handles: BenchmarkHandles(
                                            scrollController: _scrollController,
                                            context: context,
                                            tickerProvider: this,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const SpinningBigCircularProgress(
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

                // overlay when running
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

                // completed screen
                if (state.stage == BenchmarkStage.completed)
                  Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: BenchmarkResultOverlay(
                        limitedAnimationAsset: widget.limitedAnimationAsset,
                        deviceScore: state.deviceScore!,
                        featureScore: state.featureScore!,
                        performanceScore: state.performanceScore!,
                        internetResult: state.internetResult!,
                        overallBenchmarkScore: state.overallBenchmarkScore!,
                        deviceInformation: state.deviceInfo!,
                        featureResult: state.featureResults!,
                        hasHardBlocker: state.incompatible,
                        loadingAnimationAsset: widget.loadingAnimationAsset,
                        compatibleAnimationAsset:
                            widget.compatibleAnimationAsset,
                        incompatibleAnimationAsset:
                            widget.incompatibleAnimationAsset,
                        mainDomainScoresSet: widget.cfg.mainDomainScores,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
