import 'package:accessibility_frontend/domain/discovery/recommendation_models.dart';

abstract interface class ExternalActionLauncher {
  Future<ExternalActionLaunchResult> launch(PlaceExternalAction action);
}
