import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'device_and_os_event.dart';
part 'device_and_os_state.dart';

class DeviceAndOsBloc extends Bloc<DeviceAndOsEvent, DeviceAndOsState> {
  final DeviceAndOsRunner runner;
  final DeviceAndOsScorer deviceAndOsScorer;

  DeviceAndOsBloc({required this.runner, required this.deviceAndOsScorer})
    : super(const DeviceAndOsState()) {
    on<GetDeviceInformation>(_onGetDeviceInformation);
    on<ScoreDevicenOS>(_onScoreDevice);
  }

  Future<void> _onGetDeviceInformation(
    GetDeviceInformation event,
    Emitter<DeviceAndOsState> emit,
  ) async {
    emit(state.copyWith(status: DeviceAndOsStatus.loading, message: null));

    try {
      final deviceInfoResult = await runner.getDeviceInformation();

      // If you want to immediately score after fetching:
      add(ScoreDevicenOS(deviceInfo: deviceInfoResult));

      emit(
        state.copyWith(
          status: DeviceAndOsStatus.success,
          deviceInfo: deviceInfoResult,
        ),
      );
    } catch (e, st) {
      debugPrint('BNCH [DeviceBloc GetDeviceInformation] $e\n$st');
      emit(state.copyWith(status: DeviceAndOsStatus.error, message: '$e\n$st'));
    }
  }

  Future<void> _onScoreDevice(
    ScoreDevicenOS event,
    Emitter<DeviceAndOsState> emit,
  ) async {
    emit(state.copyWith(status: DeviceAndOsStatus.loading, message: null));

    try {
      final deviceInfo = event.deviceInfo;
      final results = <DeviceAndOsCheckResult>[];
      var hasHardBlocker = false;

      // --- OS Version ---
      final osVersion = double.tryParse(deviceInfo.systemVersion) ?? 0;
      final osScore = deviceAndOsScorer.scoreOSVersion(osVersion: osVersion);

      if (osScore < 0) {
        results.add(
          DeviceAndOsCheckResult(
            type: DeviceAndOsCheckType.osVersion,
            status: DeviceAndOsCheckStatus.incompatible,
            isHardBlocker: true,
            message: 'OS version is below the minimum required',
          ),
        );
        hasHardBlocker = true;
      } else {
        results.add(
          DeviceAndOsCheckResult(
            type: DeviceAndOsCheckType.osVersion,
            status: DeviceAndOsCheckStatus.supported,
            message: 'OS version supported',
          ),
        );
      }

      // --- CPU Architecture ---
      final archScore = deviceAndOsScorer.scoreCpuArchitecture(
        arch: deviceInfo.cpuArchitecture,
      );

      if (archScore < 0) {
        results.add(
          DeviceAndOsCheckResult(
            type: DeviceAndOsCheckType.cpuArchitecture,
            status: DeviceAndOsCheckStatus.incompatible,
            isHardBlocker: true,
            message: 'CPU architecture not supported',
          ),
        );
        hasHardBlocker = true;
      } else {
        results.add(
          DeviceAndOsCheckResult(
            type: DeviceAndOsCheckType.cpuArchitecture,
            status: DeviceAndOsCheckStatus.supported,
            message: 'CPU architecture supported',
          ),
        );
      }

      // --- CPU (weighted) ---
      final coresScore = deviceAndOsScorer.scoreCpuCores(
        cores: deviceInfo.cpuCores.toInt(),
      );

      final freqScore = deviceAndOsScorer.scoreCpuFrequency(
        mhz: deviceInfo.cpuFrequencyMhz.toInt(),
      );

      final cpuScore = deviceAndOsScorer.calculateCpuScore(
        arch: archScore,
        cores: coresScore,
        freq: freqScore,
      );

      // --- RAM & Storage (weighted) ---
      // ✅ ramGB expected → you already convert MB -> GB
      final ramGb = deviceInfo.availableRamMb / 1024;

      // ✅ storageGB expected → convert MB -> GB (you were passing MB before)
      final storageGb = deviceInfo.availableMemoryMb / 1024;

      final ramScore = deviceAndOsScorer.scoreAvailableRamGb(ramGb: ramGb);
      final storageScore = deviceAndOsScorer.scoreAvailableStorageGb(
        storageGb: storageGb,
      );

      final ramStorageScore = deviceAndOsScorer.calculateRamStorageScore(
        ram: ramScore,
        storage: storageScore,
      );

      // --- Final Device & OS score ---
      final finalScore = deviceAndOsScorer.calculateDeviceAndOSScore(
        os: osScore,
        ramStorage: ramStorageScore,
        cpu: cpuScore,
      );

      emit(
        state.copyWith(
          osScore: osScore,
          cpuScore: cpuScore,
          ramStorageScore: ramStorageScore,
          results: results,
          incompatible: hasHardBlocker,
          status: DeviceAndOsStatus.scored,
          deviceAndOSScore: finalScore,
          deviceInfo: deviceInfo,
        ),
      );
    } catch (e, st) {
      debugPrint('BNCH [DeviceBloc Scoring] $e\n$st');
      emit(state.copyWith(status: DeviceAndOsStatus.error, message: '$e\n$st'));
    }
  }
}
