// lib/src/config/bloc/benchmark_config_state.dart
part of 'benchmark_config_cubit.dart';

class BenchmarkConfigState extends Equatable {
  final bool isLoading;
  final BenchmarkConfig? config;
  final String? error;

  const BenchmarkConfigState._({
    required this.isLoading,
    this.config,
    this.error,
  });

  const BenchmarkConfigState.initial() : this._(isLoading: false);

  const BenchmarkConfigState.loading() : this._(isLoading: true);

  const BenchmarkConfigState.loaded(BenchmarkConfig cfg)
    : this._(isLoading: false, config: cfg);

  const BenchmarkConfigState.error(String msg)
    : this._(isLoading: false, error: msg);

  @override
  List<Object?> get props => [isLoading, config, error];
}
