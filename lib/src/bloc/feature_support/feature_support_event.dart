part of 'feature_support_bloc.dart';

sealed class FeatureSupportEvent extends Equatable {
  const FeatureSupportEvent();

  @override
  List<Object> get props => [];
}

final class StartFeatureSupportCheck extends FeatureSupportEvent {
  final List<FeatureStepType> featureRequirements;

  const StartFeatureSupportCheck({required this.featureRequirements});
}

class ScoreFeatureSupport extends FeatureSupportEvent {
  final List<FeatureSuppResult> results;

  const ScoreFeatureSupport(this.results);

  @override
  List<Object> get props => [results];
}
