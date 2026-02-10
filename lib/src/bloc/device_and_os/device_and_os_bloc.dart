import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'device_and_os_event.dart';
part 'device_and_os_state.dart';

class DeviceAndOsBloc extends Bloc<DeviceAndOsEvent, DeviceAndOsState> {
  final DeviceAndOsScorer deviceAndOsScorer;
  DeviceAndOsBloc({required this.deviceAndOsScorer})
    : super(const DeviceAndOsState()) {
    on<GetDeviceInformation>((event, emit) async {
      emit(state.copyWith(status: DeviceAndOsStatus.loading));
      try {
        final deviceInfo = DeviceAndOsRunner();
        final deviceInfoResult = await deviceInfo.getDeviceInformation();
        add(ScoreDevicenOS(deviceInfo: deviceInfoResult));
        emit(
          state.copyWith(
            status: DeviceAndOsStatus.success,
            deviceInfo: deviceInfoResult,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: DeviceAndOsStatus.error,
            message: e.toString(),
          ),
        );
      }
    });

    on<ScoreDevicenOS>((event, emit) async {
      emit(state.copyWith(status: DeviceAndOsStatus.loading));

      try {
        final deviceInfo = event.deviceInfo;
        final List<DeviceAndOsCheckResult> results = [];
        bool hasHardBlocker = false;

        // OS Version Check
        // final double osScore = -1.0; // FORCE INCOMPATIBLE FOR TEST

        final osScore = deviceAndOsScorer.scoreOSVersion(
          osVersion: double.parse(deviceInfo.systemVersion),
        );
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

        // CPU Architecture Check
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
        }

        // CPU Score
        final cpuScore = deviceAndOsScorer.calculateCpuScore(
          arch: archScore,
          cores: deviceAndOsScorer.scoreCpuCores(cores: deviceInfo.cpuCores),
          freq: deviceAndOsScorer.scoreCpuFrequency(
            deviceInfo.cpuFrequencyMhz.toInt(),
          ),
        );

        // RAM & Storage Score
        final ramScore = deviceAndOsScorer.scoreAvailableRamGb(
          deviceInfo.availableRamMb / 1024,
        );
        final storageScore = deviceAndOsScorer.scoreAvailableStorageGb(
          deviceInfo.availableMemoryMb.toDouble(),
        );
        final ramStorageScore = deviceAndOsScorer.calculateRamStorageScore(
          ram: ramScore,
          storage: storageScore,
        );

        // Final Device & OS Score
        final finalScore = deviceAndOsScorer.calculateDeviceAndOSScore(
          os: osScore,
          ramStorage: ramStorageScore,
          cpu: cpuScore,
        );

        // 🔹 Emit once with all data and deviceInfo
        emit(
          state.copyWith(
            osScore: osScore,
            cpuScore: cpuScore,
            ramStorageScore: ramStorageScore,
            results: results,
            incompatible: hasHardBlocker,
            status: DeviceAndOsStatus.scored,
            deviceAndOSScore: finalScore,
            deviceInfo: deviceInfo, // important!
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: DeviceAndOsStatus.error,
            message: e.toString(),
          ),
        );
      }
    });
  }
}
