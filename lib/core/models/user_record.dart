/// Entidad de usuario para mostrar en el Home
class UserRecord {
  final String id;
  final String name;
  final String status;
  final DateTime timestamp;
  final String? avatarUrl;

  UserRecord({required this.id, required this.name, required this.status, required this.timestamp, this.avatarUrl});

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    return UserRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'status': status, 'timestamp': timestamp.toIso8601String(), 'avatarUrl': avatarUrl};
  }
}
