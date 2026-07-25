/// Base URL of the local proxy in ../../server that holds the OpenAI/SerpAPI
/// keys server-side. Override at build/run time for Android emulators
/// (which can't reach the host via `localhost`) with:
///   flutter run --dart-define=PROXY_BASE_URL=http://10.0.2.2:8787
const proxyBaseUrl = String.fromEnvironment(
  'PROXY_BASE_URL',
  defaultValue: 'http://localhost:8787',
);
