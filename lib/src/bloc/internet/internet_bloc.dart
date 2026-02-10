import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'internet_event.dart';
part 'internet_state.dart';

class InternetBloc extends Bloc<InternetEvent, InternetState> {
  final InternetCheckerRunner internetCheckerRunner;
  InternetBloc(this.internetCheckerRunner) : super(InternetInitial()) {
    on<CheckInternetConnection>((event, emit) async {
      emit(InternetCheckInProgress());

      try {
        final result = await internetCheckerRunner.checkCConnectivity();

        emit(InternetCheckSuccess(result: result));
      } catch (e) {
        emit(InternetCheckFailed(e.toString()));
      }
    });
  }
}
