part of 'device_and_os_bloc.dart';

enum DeviceAndOsStatus {
  initial,
  loading,
  benchmarking,
  success,
  scored,
  error,
}

class DeviceAndOsState extends Equatable {
  final DeviceInformation? deviceInfo;

  /// Final weighted Device & OS score (0–100)
  final double? deviceAndOSScore;

  /// Sub-scores (useful for UI / debugging)
  final double? osScore;
  final double? cpuScore;
  final double? ramStorageScore;

  /// Hard-fail compatibility flag
  final bool incompatible;

  final DeviceAndOsStatus status;
  final List<DeviceAndOsCheckResult> results;

  final String? message;

  const DeviceAndOsState({
    this.deviceInfo,
    this.deviceAndOSScore,
    this.osScore,
    this.cpuScore,
    this.ramStorageScore,
    this.incompatible = false,
    this.status = DeviceAndOsStatus.initial,
    this.message,
    this.results = const [],
  });

  @override
  List<Object?> get props => [
    deviceInfo,
    deviceAndOSScore,
    osScore,
    cpuScore,
    ramStorageScore,
    incompatible,
    status,
    message,
  ];

  DeviceAndOsState copyWith({
    DeviceInformation? deviceInfo,
    double? deviceAndOSScore,
    double? osScore,
    double? cpuScore,
    double? ramStorageScore,
    bool? incompatible,
    DeviceAndOsStatus? status,
    String? message,
    List<DeviceAndOsCheckResult>? results,
  }) {
    return DeviceAndOsState(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      deviceAndOSScore: deviceAndOSScore ?? this.deviceAndOSScore,
      osScore: osScore ?? this.osScore,
      cpuScore: cpuScore ?? this.cpuScore,
      ramStorageScore: ramStorageScore ?? this.ramStorageScore,
      incompatible: incompatible ?? this.incompatible,
      status: status ?? this.status,
      message: message ?? this.message,
      results: results ?? this.results,
    );
  }
}
