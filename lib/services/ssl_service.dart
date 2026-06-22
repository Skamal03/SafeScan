import 'dart:io';

class SslService {
  static Future<Map<String, dynamic>> verifyCertificate(String url) async {
    // 1. Clean the host name
    String host = url
        .replaceFirst('https://', '')
        .replaceFirst('http://', '')
        .split('/')[0]
        .split(':')[0]
        .trim();

    if (host.isEmpty) throw Exception('INVALID_HOST');

    try {
      // 2. DNS Lookup check (to see if the site even exists)
      try {
        await InternetAddress.lookup(host).timeout(const Duration(seconds: 5));
      } catch (_) {
        throw Exception('HOST_NOT_FOUND');
      }

      // 3. Connect via secure socket
      // We use onBadCertificate: (cert) => true to inspect any certificate
      SecureSocket socket = await SecureSocket.connect(
        host,
        443,
        timeout: const Duration(seconds: 10),
        onBadCertificate: (X509Certificate cert) => true, 
      );

      X509Certificate? cert = socket.peerCertificate;
      socket.destroy();

      if (cert == null) throw Exception('NO_CERTIFICATE_FOUND');

      DateTime now = DateTime.now();
      // Valid if now is between start and end
      bool isExpired = now.isAfter(cert.endValidity);
      bool isNotYetValid = now.isBefore(cert.startValidity);
      bool isValid = !isExpired && !isNotYetValid;
      
      int daysRemaining = cert.endValidity.difference(now).inDays;

      return {
        'status': isValid ? 'valid' : (isExpired ? 'expired' : 'invalid'),
        'host': host,
        'issuer': _parseCertField(cert.issuer, 'CN') ?? cert.issuer,
        'expiry': cert.endValidity.toIso8601String().split('T')[0],
        'daysRemaining': daysRemaining,
        'subject': _parseCertField(cert.subject, 'CN') ?? cert.subject,
        'isValid': isValid,
        'fullIssuer': cert.issuer,
      };
    } on SocketException catch (e) {
      print("SSL Socket Error for $host: $e");
      throw Exception('CONNECTION_REFUSED');
    } catch (e) {
      print("SSL General Error for $host: $e");
      rethrow;
    }
  }

  static String? _parseCertField(String text, String field) {
    try {
      final pattern = RegExp('$field=([^,]+)');
      final match = pattern.firstMatch(text);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }
}
