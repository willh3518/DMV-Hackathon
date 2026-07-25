import 'package:accessibility_frontend/contracts/discovery_gateway.dart';
import 'package:accessibility_frontend/domain/chat/chat_models.dart';

/// Deterministic Chat fixture that never retains submitted request text.
final class SyntheticDiscoveryGateway implements DiscoveryGateway {
  SyntheticDiscoveryGateway({required List<DiscoveryResult> results})
    : assert(results.isNotEmpty),
      _results = List<DiscoveryResult>.of(results);

  final List<DiscoveryResult> _results;
  int callCount = 0;

  @override
  Future<DiscoveryResult> send(DiscoveryRequest request) async {
    final int resultIndex = callCount.clamp(0, _results.length - 1);
    callCount += 1;
    return _results[resultIndex];
  }
}
