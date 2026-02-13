// lib/src/config/repo/benchmark_config_repository.dart
import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:app_compat_benchmark_flutter/src/api/becnhmark_config_api.dart';
import 'package:flutter/material.dart';

class BenchmarkConfigRepository {
  final BenchmarkConfigApi api;

  BenchmarkConfigRepository(this.api);

  Future<BenchmarkConfig> getConfig() async {
    try {
      final payload = await api.fetchConfig();
      debugPrint("BenchmarkConfigRepository payloadd: $payload");
      return BenchmarkConfig.fromJson(payload);
    } catch (e, stackTrace) {
      debugPrint("BenchmarkConfigRepository Error: $e");
      debugPrint("StackTrace: $stackTrace");

      // Re-throw so Bloc can emit failure state
      throw Exception("Failed to load benchmark configuration");
    }
  }
}
