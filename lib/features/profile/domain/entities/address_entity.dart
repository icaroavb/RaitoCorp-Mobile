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
