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

  factory ProductEntity.fromJson(Map<String, dynamic> json) => ProductEntity(
        id: json['id'].toString(),
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        originalPrice: (json['original_price'] as num?)?.toDouble(),
        imageUrls: (json['image_urls'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        lightTemperature: _enumFromString(
          LightTemperature.values,
          json['light_temperature'] as String?,
          LightTemperature.warm,
        ),
        socketType: json['socket_type'] as String? ?? '',
        isBivolt: json['is_bivolt'] as bool? ?? false,
        isEasyInstall: json['is_easy_install'] as bool? ?? false,
        energySavingPercent: (json['energy_saving_percent'] as num?)?.toInt() ?? 0,
        lifespanYears: (json['lifespan_years'] as num?)?.toInt() ?? 0,
        brightnessLevel: _enumFromString(
          BrightnessLevel.values,
          json['brightness_level'] as String?,
          BrightnessLevel.medium,
        ),
        idealRooms: (json['ideal_rooms'] as List? ?? const [])
            .map((e) => _enumFromString(Room.values, e.toString(), Room.living))
            .toList(),
        powerWatts: (json['power_watts'] as num?)?.toInt() ?? 0,
        lumens: (json['lumens'] as num?)?.toInt() ?? 0,
        colorTemperatureK: (json['color_temperature_k'] as num?)?.toInt() ?? 0,
        dimensions: json['dimensions'] as String? ?? '',
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
        certifications: (json['certifications'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        warrantyYears: (json['warranty_years'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        soldCount: (json['sold_count'] as num?)?.toInt() ?? 0,
        isBestSeller: json['is_best_seller'] as bool? ?? false,
        category: _enumFromString(
          ProductCategory.values,
          json['category'] as String?,
          ProductCategory.lamp,
        ),
        tags: (json['tags'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        if (originalPrice != null) 'original_price': originalPrice,
        'image_urls': imageUrls,
        'light_temperature': lightTemperature.name,
        'socket_type': socketType,
        'is_bivolt': isBivolt,
        'is_easy_install': isEasyInstall,
        'energy_saving_percent': energySavingPercent,
        'lifespan_years': lifespanYears,
        'brightness_level': brightnessLevel.name,
        'ideal_rooms': idealRooms.map((r) => r.name).toList(),
        'power_watts': powerWatts,
        'lumens': lumens,
        'color_temperature_k': colorTemperatureK,
        'dimensions': dimensions,
        'weight_kg': weightKg,
        'certifications': certifications,
        'warranty_years': warrantyYears,
        'rating': rating,
        'review_count': reviewCount,
        'sold_count': soldCount,
        'is_best_seller': isBestSeller,
        'category': category.name,
        'tags': tags,
      };

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
