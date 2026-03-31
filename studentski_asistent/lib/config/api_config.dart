import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Jedan ulaz (Nginx gateway) — u Docker Compose mapiran na host port **8088**.
/// Primer: `http://localhost:8088` → `/auth/*` i `/api/*`
String defaultGatewayUrl() {
  if (kIsWeb) {
    return 'http://localhost:8088';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8088';
  }
  return 'http://localhost:8088';
}

/// `--dart-define=GATEWAY_URL=http://192.168.1.5` za telefon u LAN-u (gateway na PC-ju port 80).
String resolveGatewayUrl() {
  const fromEnv = String.fromEnvironment('GATEWAY_URL', defaultValue: '');
  if (fromEnv.isNotEmpty) {
    return fromEnv.replaceAll(RegExp(r'/$'), '');
  }
  return defaultGatewayUrl();
}
