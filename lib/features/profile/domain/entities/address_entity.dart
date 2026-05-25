import 'package:equatable/equatable.dart';

class AddressEntity extends Equatable {
  final String id;
  final String label;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  const AddressEntity({
    required this.id,
    required this.label,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  factory AddressEntity.fromJson(Map<String, dynamic> json) => AddressEntity(
        id: json['id'].toString(),
        label: json['label'] as String? ?? 'Endereço',
        street: json['street'] as String? ?? '',
        number: json['number']?.toString() ?? '',
        complement: json['complement'] as String?,
        neighborhood: json['neighborhood'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        zipCode: json['zip_code'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'street': street,
        'number': number,
        if (complement != null) 'complement': complement,
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'is_default': isDefault,
      };

  String get line1 =>
      '$street, $number${complement != null && complement!.isNotEmpty ? ', $complement' : ''}';
  String get line2 => '$neighborhood · $city – $state';
  String get line3 => 'CEP: $zipCode';

  AddressEntity copyWith({bool? isDefault}) => AddressEntity(
        id: id,
        label: label,
        street: street,
        number: number,
        complement: complement,
        neighborhood: neighborhood,
        city: city,
        state: state,
        zipCode: zipCode,
        isDefault: isDefault ?? this.isDefault,
      );

  @override
  List<Object?> get props => [id];
}
