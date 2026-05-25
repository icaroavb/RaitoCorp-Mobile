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

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? (json['email'] as String);
    return UserEntity(
      email: json['email'] as String,
      name: name,
      initials: (json['initials'] as String?) ?? _initials(name),
      isAdmin: json['is_admin'] as bool? ?? false,
      memberSince: DateTime.parse(json['member_since'] as String).toLocal(),
      phone: json['phone'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String).toLocal(),
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'initials': initials,
        'is_admin': isAdmin,
        'member_since': memberSince.toUtc().toIso8601String(),
        if (phone != null) 'phone': phone,
        if (birthDate != null)
          'birth_date': birthDate!.toUtc().toIso8601String(),
        'loyalty_points': loyaltyPoints,
      };

  UserEntity copyWith({
    String? name,
    String? phone,
    DateTime? birthDate,
  }) =>
      UserEntity(
        email: email,
        name: name ?? this.name,
        initials: name == null ? initials : _initials(name),
        isAdmin: isAdmin,
        memberSince: memberSince,
        phone: phone ?? this.phone,
        birthDate: birthDate ?? this.birthDate,
        loyaltyPoints: loyaltyPoints,
      );

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [email];
}
