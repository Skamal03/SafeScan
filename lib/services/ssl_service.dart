import 'dart:io';

class SslService {
  static Future<Map<String, dynamic>> verifyCertificate(String url) async {
    // Clean URL
    String host = url.replaceFirst('https://', '').replaceFirst('http://', '').split('/')[0];
    
    try {
      // Connect via secure socket to get the certificate
      SecureSocket socket = await SecureSocket.connect(
        host, 
        443, 
        timeout: const Duration(seconds: 5)
      );
      
      X509Certificate? cert = socket.peerCertificate;
      socket.destroy();

      if (cert == null) throw Exception('NO_CERTIFICATE_FOUND');

      DateTime now = DateTime.now();
      bool isValid = cert.endValidity.isAfter(now);
      
      return {
        'status': isValid ? 'valid' : 'expired',
        'host': host,
        'issuer': cert.issuer,
        'expiry': cert.endValidity.toIso8601String().split('T')[0],
        'subject': cert.subject,
        'isValid': isValid,
      };
    } catch (e) {
      throw Exception('FAILED_TO_FETCH_CERTIFICATE: $e');
    }
  }
}
