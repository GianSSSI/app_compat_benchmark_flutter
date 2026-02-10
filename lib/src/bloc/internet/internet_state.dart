part of 'internet_bloc.dart';

sealed class InternetState extends Equatable {
  const InternetState();

  @override
  List<Object> get props => [];
}

final class InternetInitial extends InternetState {}

final class InternetCheckInProgress extends InternetState {}

final class InternetCheckFailed extends InternetState {
  final String errorMessage;

  const InternetCheckFailed(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

final class InternetCheckSuccess extends InternetState {
  final InternetCheckResult result;

  const InternetCheckSuccess({required this.result});
}
