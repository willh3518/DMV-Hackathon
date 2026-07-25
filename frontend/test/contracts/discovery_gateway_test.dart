import 'package:accessibility_frontend/domain/chat/chat_models.dart';
import 'package:accessibility_frontend/fixtures/synthetic_discovery_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'synthetic discovery returns ordered results without retaining text',
    () async {
      final SyntheticDiscoveryGateway gateway = SyntheticDiscoveryGateway(
        results: const <DiscoveryResult>[
          DiscoveryClarification(
            conversationId: 'conversation-1',
            message: 'Would you prefer a quieter time of day?',
          ),
          DiscoveryNoResults(
            conversationId: 'conversation-1',
            message: 'No matching places were supplied.',
          ),
        ],
      );

      final DiscoveryResult first = await gateway.send(
        const DiscoveryRequest(text: 'Invented accessibility request'),
      );
      final DiscoveryResult second = await gateway.send(
        const DiscoveryRequest(text: 'Invented clarification answer'),
      );

      expect(first, isA<DiscoveryClarification>());
      expect(second, isA<DiscoveryNoResults>());
      expect(gateway.callCount, 2);
    },
  );
}
