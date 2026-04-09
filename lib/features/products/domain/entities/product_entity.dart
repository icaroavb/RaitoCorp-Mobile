import 'package:equatable/equatable.dart';

enum LightTemperature { warm, neutral, cool }

enum BrightnessLevel { soft, medium, intense }

enum Room { bedroom, living, kitchen, bathroom, external, office, diningRoom }

enum ProductCategory { pendant, lamp, wallLamp, spot, strip, floorLamp, smart }

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final List<String> imageUrls;
  final LightTemperature lightTemperature;
  final String socketType;
  final bool isBivolt;
  final bool isEasyInstall;
  final int energySavingPercent;
  final int lifespanYears;
  final BrightnessLevel brightnessLevel;
  final List<Room> idealRooms;
  final int powerWatts;
  final int lumens;
  final int colorTemperatureK;
  final String dimensions;
  final double weightKg;
  final List<String> certifications;
  final int warrantyYears;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final bool isBestSeller;
  final ProductCategory category;
  final List<String> tags;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.imageUrls,
    required this.lightTemperature,
    required this.socketType,
    required this.isBivolt,
    required this.isEasyInstall,
    required this.energySavingPercent,
    required this.lifespanYears,
    required this.brightnessLevel,
    required this.idealRooms,
    required this.powerWatts,
    required this.lumens,
    required this.colorTemperatureK,
    required this.dimensions,
    required this.weightKg,
    required this.certifications,
    required this.warrantyYears,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.isBestSeller,
    required this.category,
    required this.tags,
  });

  @override
  List<Object?> get props => [id];
}

extension RoomLabel on Room {
  String get label => switch (this) {
        Room.bedroom => 'Quarto',
        Room.living => 'Sala de estar',
        Room.kitchen => 'Cozinha',
        Room.bathroom => 'Banheiro',
        Room.external => 'Externo',
        Room.office => 'Escritório',
        Room.diningRoom => 'Sala de jantar',
      };
}

extension LightTemperatureLabel on LightTemperature {
  String get label => switch (this) {
        LightTemperature.warm => 'Luz quente',
        LightTemperature.neutral => 'Luz neutra',
        LightTemperature.cool => 'Luz fria',
      };

  String get description => switch (this) {
        LightTemperature.warm => 'Quente — aconchegante',
        LightTemperature.neutral => 'Neutra — versátil',
        LightTemperature.cool => 'Fria — produtiva',
      };
}

extension BrightnessLevelLabel on BrightnessLevel {
  String get label => switch (this) {
        BrightnessLevel.soft => 'Suave',
        BrightnessLevel.medium => 'Médio',
        BrightnessLevel.intense => 'Intenso',
      };

  double get sliderValue => switch (this) {
        BrightnessLevel.soft => 0.25,
        BrightnessLevel.medium => 0.6,
        BrightnessLevel.intense => 0.9,
      };
}
