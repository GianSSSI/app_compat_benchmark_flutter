import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';

List<FeatureStepType> requiredStepsFromConfig(RequiredFeatures rf) {
  final steps = <FeatureStepType>[];

  if (rf.camera) steps.add(FeatureStepType.camera);

  // your payload has gps + location
  if (rf.gps || rf.location) steps.add(FeatureStepType.gps);

  if (rf.nfc) steps.add(FeatureStepType.nfc);

  return steps;
}
