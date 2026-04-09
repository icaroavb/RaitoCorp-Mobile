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
