import 'dart:convert';
import 'dart:io';
import 'loki_service.dart';
import 'models.dart';
import 'utils.dart';

class LogWebSocketServer {
  final int port;
  HttpServer? _server;
  final Set<WebSocket> _clients = {};

  LogWebSocketServer({this.port = 6008});

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      Logger.log(
        'WebSocket Server is running on ws://${_server!.address.address}:$port',
      );

      await for (var request in _server!) {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add(
          'Access-Control-Allow-Methods',
          'GET, POST, OPTIONS',
        );
        request.response.headers.add(
          'Access-Control-Allow-Headers',
          'Content-Type',
        );

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.noContent;
          request.response.close();
          continue;
        }

        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          _handleConnection(socket);
        } else {
          request.response.statusCode = HttpStatus.forbidden;
          request.response.close();
        }
      }
    } catch (e) {
      Logger.error('Failed to start server: $e');
      _restartServer();
    }
  }

  void _handleConnection(WebSocket socket) async {
    _clients.add(socket);
    Logger.log('New client connected. Total clients: ${_clients.length}');

    final welcome = {"success": true, "message": "Connected to log server."};
    socket.add(jsonEncode(welcome));

    try {
      final logs = await LokiService().queryAll();
      final logList = logs.map((log) => log.toJson()).toList();

      socket.add(jsonEncode({"type": "initial_logs", "data": logList}));
    } catch (e) {
      Logger.error('Failed to fetch initial logs from Loki: $e');
      socket.add(
        jsonEncode({
          "type": "initial_logs",
          "data": [],
          "error": "Unable to fetch initial logs",
        }),
      );
    }

    socket.listen(
      (data) => _handleMessage(socket, data),
      onDone: () {
        _clients.remove(socket);
        Logger.log('Client disconnected. Total clients: ${_clients.length}');
      },
      onError: (e) {
        Logger.error('WebSocket error: $e');
        _clients.remove(socket);
      },
      cancelOnError: true,
    );
  }

  void _handleMessage(WebSocket sender, dynamic data) async {
    try {
      final parsed = jsonDecode(data);

      if (parsed is! Map<String, dynamic> ||
          !parsed.containsKey('level') ||
          !parsed.containsKey('message')) {
        sender.add(
          jsonEncode({
            "success": false,
            "error": "Missing required fields: 'level' and 'message'.",
          }),
        );
        return;
      }

      final log = LogModel.fromJson(parsed);

      await LokiService.sendToLoki(log);

      final logJson = log.toJson();
      _broadcast(logJson, sender);

      sender.add(jsonEncode({"success": true, "data": logJson}));
    } catch (e) {
      sender.add(
        jsonEncode({
          "success": false,
          "error": "Malformed JSON or internal error: $e",
        }),
      );
    }
  }

  void _broadcast(Map<String, dynamic> log, WebSocket exclude) {
    final message = jsonEncode({"success": true, "data": log});

    for (final client in _clients) {
      if (client == exclude) continue;
      try {
        client.add(message);
      } catch (e) {
        print('Failed to broadcast to client: $e');
      }
    }
  }

  void _restartServer() async {
    Logger.log('Restarting server...');
    await _server?.close(force: true);
    await start();
  }
}
