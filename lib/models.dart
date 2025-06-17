class LogModel {
  final String level;
  final String? source;
  final String message;
  final String? route;
  final DateTime timestamp;

  LogModel({
    required this.level,
    required this.source,
    required this.message,
    this.route,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      level: json['level'],
      source: json['source'],
      message: json['message'],
      route: json['route'],
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'])?.toUtc()
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'source': source,
    'message': message,
    'route': route,
    'timestamp': timestamp.toIso8601String(),
  };
}
