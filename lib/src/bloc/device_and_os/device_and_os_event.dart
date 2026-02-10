part of 'device_and_os_bloc.dart';

sealed class DeviceAndOsEvent extends Equatable {
  const DeviceAndOsEvent();

  @override
  List<Object> get props => [];
}

final class GetDeviceInformation extends DeviceAndOsEvent {}

final class ScoreDevicenOS extends DeviceAndOsEvent {
  final DeviceInformation deviceInfo;

  const ScoreDevicenOS({required this.deviceInfo});
}
