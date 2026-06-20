import 'dart:convert';
import 'package:http/http.dart' as http;

class SafeScanService {
  //  FIXED: Base URL should ONLY be the raw domain name root
  static const String _baseUrl = "https://voter-cardiac-roundish.ngrok-free.dev";

  Future<Map<String, dynamic>?> queryIntent(String message) async {
    try {
      print("--- SAFESCAN API CALL ---");
      print("Message: $message");

      //  Now cleanly resolves to: https://...ngrok-free.dev/predict
      final response = await http.post(
        Uri.parse("$_baseUrl/predict"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode({
          "message": message,
        }),
      ).timeout(const Duration(seconds: 60));

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } else {
        print("SERVER ERROR: ${response.statusCode}");
      }
    } catch (e) {
      print("CONNECTION ERROR: $e");
    }
    return null;
  }

  // Health check — call this on app start to verify server is up
  Future<bool> isServerAlive() async {
    try {
      //  Now cleanly resolves to: https://...ngrok-free.dev/health
      final response = await http.get(
        Uri.parse("$_baseUrl/health"),
        headers: {"ngrok-skip-browser-warning": "true"},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}