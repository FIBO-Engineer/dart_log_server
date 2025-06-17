class Logger {
  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] INFO: $message');
  }

  static void error(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] ERROR: $message');
  }
}
