part of 'feature_support_bloc.dart';

sealed class FeatureSupportState extends Equatable {
  const FeatureSupportState();

  @override
  List<Object?> get props => [];
}

final class FeatureSupportInitial extends FeatureSupportState {}

final class FeatureSupportChecking extends FeatureSupportState {
  final FeatureStepType currentStep;
  const FeatureSupportChecking(this.currentStep);

  @override
  List<Object?> get props => [currentStep];
}

final class FeatureSupportError extends FeatureSupportState {
  final FeatureStepType currentStep;
  final String message;

  const FeatureSupportError(this.message, this.currentStep);

  @override
  List<Object?> get props => [message, currentStep];
}

final class FeatureSupportScored extends FeatureSupportState {
  final List<FeatureSuppResult> results;
  final FeatureSupportScore score;
  final bool hasHardBlocker;

  const FeatureSupportScored(this.results, this.score, this.hasHardBlocker);

  @override
  List<Object?> get props => [results, score, hasHardBlocker];
}
