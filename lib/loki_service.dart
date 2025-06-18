import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'utils.dart';

class LokiService {
  static const String _pushUrl = 'http://loki:3100/loki/api/v1/push';
  static const String _queryUrlBase =
      'http://loki:3100/loki/api/v1/query_range';

  static Future<void> sendToLoki(LogModel log) async {
    final response = await http.post(
      Uri.parse(_pushUrl),
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
            'route': log.route ?? '',
          },
          'values': [
            [
              (log.timestamp.millisecondsSinceEpoch * 1000000).toString(),
              log.message,
            ],
          ],
        },
      ],
    });
  }

  Future<List<LogEntry>> queryRange({
    required DateTime start,
    required DateTime end,
    int limit = 1000,
    String direction = 'BACKWARD',
  }) async {
    final query = {
      'query': '{level=~".+"}',
      'start': (start.millisecondsSinceEpoch * 1000000).toString(),
      'end': (end.millisecondsSinceEpoch * 1000000).toString(),
      'limit': limit.toString(),
      'direction': direction,
    };

    final uri = Uri.parse(_queryUrlBase).replace(queryParameters: query);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final entries = <LogEntry>[];

      final result = data['data']['result'] as List;
      for (var stream in result) {
        final streams = stream['stream'] as Map<String, dynamic>;
        final values = stream['values'] as List;

        for (var value in values) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            (int.parse(value[0]) / 1000000).round(),
            isUtc: true,
          );

          final rawMessage = value[1];

          entries.add(
            LogEntry(
              timestamp: timestamp,
              message: rawMessage,
              level: streams['level'] ?? '',
              source: streams['source'] ?? '',
              route: streams['route'] ?? '',
            ),
          );
        }
      }

      return entries;
    } else {
      Logger.error(
        'Loki query failed: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to query Loki');
    }
  }

  Future<List<LogEntry>> queryAll() async {
    final end = DateTime.now().toUtc();
    final start = end.subtract(const Duration(days: 7));
    return await queryRange(start: start, end: end);
  }
}
