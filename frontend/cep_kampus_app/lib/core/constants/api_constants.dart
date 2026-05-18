/// Central location for all network configuration.
/// Change [baseUrl] here when switching between localhost, LAN IP, or ngrok.
class ApiConstants {
  ApiConstants._();

  /// For Android emulator use http://10.0.2.2:8000
  /// For physical device on the same network use http://<YOUR_LAN_IP>:8000
  /// For ngrok use https://<your-subdomain>.ngrok.io
  static const String baseUrl = 'http://192.168.1.112:8000';

  static const String askEndpoint = '/ask';
  static const String healthEndpoint = '/health';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 60);
}