import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:app_compat_benchmark_flutter/app_compat_benchmark_flutter.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/overlays/benchmark_results_overlay.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/progress/circular_progrees.dart';
import 'package:app_compat_benchmark_flutter/src/widgets/progress/linear_progress_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BenchmarkPage extends StatefulWidget {
  final DomainWeightsSet? domainWeightsSet;
  const BenchmarkPage({super.key, this.domainWeightsSet});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();

  DomainWeightsSet get domainWeights =>
      domainWeightsSet ?? DomainWeightsDefaultBundle.defaults;
}

class _BenchmarkPageState extends State<BenchmarkPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final BenchmarkRunner _benchmarkRunner = BenchmarkRunner();
  final FeatureCheckerRunner _featureCheckerRunner = FeatureCheckerRunner();
  final InternetCheckerRunner _internetCheckerRunner = InternetCheckerRunner();
  final FeatureSupportScorer _featureSupportScorer = FeatureSupportScorer();
  final DeviceAndOsScorer _deviceAndOsScorer = DeviceAndOsScorer();

  late final DeviceAndOsBloc _deviceBloc;
  late final FeatureSupportBloc _featureBloc;
  late final PerformanceBloc _performanceBloc;
  late final AppCompatMainBloc _appCompatMainBloc;
  late final InternetBloc _internetBloc;
  late final DomainScorer _domainScorer;
  @override
  void initState() {
    super.initState();
    _deviceBloc = DeviceAndOsBloc(deviceAndOsScorer: _deviceAndOsScorer);
    _featureBloc = FeatureSupportBloc(
      runner: _featureCheckerRunner,
      scorer: _featureSupportScorer,
    );
    _performanceBloc = PerformanceBloc(_benchmarkRunner);
    _internetBloc = InternetBloc(_internetCheckerRunner);
    _appCompatMainBloc = AppCompatMainBloc(
      deviceBloc: _deviceBloc,
      featureBloc: _featureBloc,
      performanceBloc: _performanceBloc,
      internetBloc: _internetBloc,
      domainScorer: _domainScorer,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _deviceBloc.close();
    _featureBloc.close();
    _performanceBloc.close();
    _appCompatMainBloc.close();
    _internetBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _deviceBloc),
        BlocProvider.value(value: _featureBloc),
        BlocProvider.value(value: _performanceBloc),
        BlocProvider.value(value: _appCompatMainBloc),
        BlocProvider.value(value: _internetBloc),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Device Benchmark')),
        body: BlocConsumer<AppCompatMainBloc, AppCompatMainState>(
          listener: (context, state) {
            // if (state.stage == BenchmarkStage.completed) {
            //   Navigator.of(context).push(
            //     MaterialPageRoute(
            //       builder: (context) => BenchmarkResultPage(
            //         deviceScore: state.deviceScore!,
            //         featureScore: state.featureScore!,
            //         performanceScore: state.performanceScore!,
            //         internetResult: state.internetResult!,
            //         finalScore: state.finalScore!,
            //         deviceInformation: state.deviceInfo!,
            //       ),
            //     ),
            //   );
            // }
          },
          builder: (context, state) {
            // determine progress
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
                              child: Text("$i", style: TextStyle(fontSize: 14)),
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
                                              Text("Device and OS"),
                                              SizedBox(height: 8),
                                              Expanded(
                                                child: StaticProgressBar(
                                                  progress: widget
                                                      .domainWeights
                                                      .deviceAndOs
                                                      .value,
                                                  text:
                                                      "${(widget.domainWeights.deviceAndOs.value * 100).toStringAsFixed(0)}%",
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
                                                    Text("Performance"),
                                                    SizedBox(height: 8),
                                                    Expanded(
                                                      child: StaticProgressBar(
                                                        progress: widget
                                                            .domainWeights
                                                            .performance
                                                            .value,
                                                        text:
                                                            "${(widget.domainWeights.performance.value * 100).toStringAsFixed(0)}%",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text("Feature Support"),
                                                    SizedBox(height: 8),
                                                    Expanded(
                                                      child: StaticProgressBar(
                                                        progress: widget
                                                            .domainWeights
                                                            .featureSuppport
                                                            .value,
                                                        text:
                                                            "${(widget.domainWeights.featureSuppport.value * 100).toStringAsFixed(0)}%",
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
                        overallBenchmarkScore: state.overallBenchmarkScore!,
                        deviceInformation: state.deviceInfo!,
                        featureResult: state.featureResults!,
                        hasHardBlocker: state.incompatible,
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
