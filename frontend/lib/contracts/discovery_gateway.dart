import 'package:accessibility_frontend/domain/chat/chat_models.dart';

abstract interface class DiscoveryGateway {
  Future<DiscoveryResult> send(DiscoveryRequest request);
}
