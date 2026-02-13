// lib/src/config/bloc/benchmark_config_cubit.dart
import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:app_compat_benchmark_flutter/src/repository/benchmark_config_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

part 'benchmark_config_state.dart';

class BenchmarkConfigCubit extends Cubit<BenchmarkConfigState> {
  final BenchmarkConfigRepository repo;

  BenchmarkConfigCubit(this.repo) : super(const BenchmarkConfigState.initial());

  Future<void> load() async {
    emit(const BenchmarkConfigState.loading());
    try {
      debugPrint("BenchmarkConfigCubit running");

      final cfg = await repo.getConfig();
      debugPrint("BenchmarkConfigCubit cfg $cfg");
      emit(BenchmarkConfigState.loaded(cfg));
    } catch (e) {
      debugPrint("BenchmarkConfigCubit error: $e");
      emit(BenchmarkConfigState.error(e.toString()));
    }
  }
}
