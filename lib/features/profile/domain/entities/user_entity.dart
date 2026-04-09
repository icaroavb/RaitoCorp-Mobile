import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String email;
  final String name;
  final String initials;
  final bool isAdmin;
  final DateTime memberSince;
  final String? phone;
  final DateTime? birthDate;
  final int loyaltyPoints;

  const UserEntity({
    required this.email,
    required this.name,
    required this.initials,
    required this.isAdmin,
    required this.memberSince,
    this.phone,
    this.birthDate,
    this.loyaltyPoints = 0,
  });

  UserEntity copyWith({
    String? name,
    String? phone,
    DateTime? birthDate,
  }) =>
      UserEntity(
        email: email,
        name: name ?? this.name,
        initials: initials,
        isAdmin: isAdmin,
        memberSince: memberSince,
        phone: phone ?? this.phone,
        birthDate: birthDate ?? this.birthDate,
        loyaltyPoints: loyaltyPoints,
      );

  @override
  List<Object?> get props => [email];
}
