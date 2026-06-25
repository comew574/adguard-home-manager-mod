import 'dart:convert';
import 'dart:io';
import 'dart:async';

class PortScanner {
  static const List<int> commonPorts = [3000, 80, 443, 8080, 3001, 8443, 9090, 9443, 18000];

  /// Scan common ports on [host] and return the port where AdGuard Home is found.
  /// Returns null if no AdGuard Home found.
  static Future<int?> scan(String host, {List<int>? ports, Duration timeout = const Duration(milliseconds: 400)}) async {
    final scanPorts = ports ?? commonPorts;
    
    for (final port in scanPorts) {
      try {
        final scheme = port == 443 ? 'https' : 'http';
        final url = Uri.parse('$scheme://$host:$port/control/status');
        
        final client = HttpClient()
          ..connectionTimeout = timeout;
        
        try {
          final request = await client.getUrl(url);
          final response = await request.close().timeout(timeout);
          
          if (response.statusCode == 200) {
            final body = await response.transform(utf8.decoder).join();
            if (body.contains('version')) {
              client.close(force: true);
              return port;
            }
          }
        } finally {
          client.close(force: true);
        }
      } catch (_) {
        // continue to next port
      }
    }
    return null;
  }
}
