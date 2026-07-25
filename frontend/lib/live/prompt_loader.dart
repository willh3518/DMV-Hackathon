import 'package:flutter/services.dart' show rootBundle;

/// Combines the assistant persona/intake prompt with the SerpAPI data-sourcing
/// steering rules into one system prompt for [LiveDiscoveryGateway]. Both
/// files are mirrored from the repo-root docs (SYSTEM_PROMPT.md and
/// docs/steering/serpapi-data-sourcing.md) — keep them in sync if those change.
Future<String> loadSystemPrompt() async {
  final persona = await rootBundle.loadString('assets/system_prompt.md');
  final steering = await rootBundle.loadString('assets/steering/serpapi_data_sourcing.md');
  return '$persona\n\n---\n\n$steering';
}
