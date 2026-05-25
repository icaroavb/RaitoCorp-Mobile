import 'package:equatable/equatable.dart';

enum AppNotificationType { order, promotion, system, review }

class AppNotification extends Equatable {
  final String id;
  final String userEmail;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.userEmail,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        userEmail: json['user_email'] as String,
        type: _enumFromString(
          AppNotificationType.values,
          json['type'] as String?,
          AppNotificationType.system,
        ),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        read: json['read'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_email': userEmail,
        'type': type.name,
        'title': title,
        'body': body,
        'created_at': createdAt.toUtc().toIso8601String(),
        'read': read,
      };

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        userEmail: userEmail,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  @override
  List<Object?> get props => [id];
}

T _enumFromString<T extends Enum>(List<T> values, String? raw, T fallback) {
  if (raw == null) return fallback;
  for (final v in values) {
    if (v.name.toLowerCase() == raw.toLowerCase()) return v;
  }
  return fallback;
}
