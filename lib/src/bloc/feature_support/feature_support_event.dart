part of 'feature_support_bloc.dart';

sealed class FeatureSupportEvent extends Equatable {
  const FeatureSupportEvent();

  @override
  List<Object?> get props => [];
}

final class StartFeatureSupportCheck extends FeatureSupportEvent {
  final List<FeatureStepType> featureRequirements;
  const StartFeatureSupportCheck({required this.featureRequirements});

  @override
  List<Object?> get props => [featureRequirements];
}
