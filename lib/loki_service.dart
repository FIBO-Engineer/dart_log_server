import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class LokiService {
  static const String _lokiUrl = 'http://loki:3100/loki/api/v1/push';

  static Future<void> sendToLoki(LogModel log) async {
    final response = await http.post(
      Uri.parse(_lokiUrl),
      headers: {'Content-Type': 'application/json'},
      body: _formatLog(log),
    );
    if (response.statusCode != 204) {
      throw Exception(
        'Failed to send log to Loki: ${response.statusCode} ${response.body}',
      );
    }
  }

  static String _formatLog(LogModel log) {
    return jsonEncode({
      'streams': [
        {
          'stream': {
            'level': log.level,
            'source': log.source,
            'route': log.route ?? 'unknown',
          },
          'values': [
            [
              (log.timestamp.millisecondsSinceEpoch * 1000000).toString(),
              jsonEncode(log.toJson()),
            ],
          ],
        },
      ],
    });
  }
}
