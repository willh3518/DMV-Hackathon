import 'package:accessibility_frontend/contracts/external_action_launcher.dart';
import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';

final class SyntheticExternalActionLauncher implements ExternalActionLauncher {
  SyntheticExternalActionLauncher({
    this.result = const ExternalActionLaunchSuccess(),
  });

  final ExternalActionLaunchResult result;
  int callCount = 0;

  @override
  Future<ExternalActionLaunchResult> launch(PlaceExternalAction action) async {
    callCount += 1;
    return result;
  }
}
