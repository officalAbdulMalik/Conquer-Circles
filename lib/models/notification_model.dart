class UserNotification {
  final String id;
  final String userId;
  final String type;
  final String? territoryId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime sentDate;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.territoryId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.sentDate,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      territoryId: json['territory_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      sentDate: DateTime.parse(json['sent_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'territory_id': territoryId,
      'title': title,
      'message': message,
      'is_read': isRead,
      'sent_date': sentDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}
