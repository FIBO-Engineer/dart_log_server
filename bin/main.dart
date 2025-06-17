import 'package:dart_log_server/server.dart';

void main() {
  final server = LogWebSocketServer(port: 6008);
  server.start();
}
