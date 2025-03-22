class Photo {
  final String id;
  final String url;
  final DateTime timestamp;
  final String? description;

  Photo({
    required this.id,
    required this.url,
    required this.timestamp,
    this.description,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      url: json['url'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }
}