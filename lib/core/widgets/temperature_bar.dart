import 'package:flutter/material.dart';

import '../../features/products/domain/entities/product_entity.dart';

class TemperatureBar extends StatelessWidget {
  final LightTemperature temperature;
  final double height;
  final BorderRadius? borderRadius;

  const TemperatureBar({
    required this.temperature,
    this.height = 4,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = switch (temperature) {
      LightTemperature.warm => const LinearGradient(
          colors: [Color(0xFFF5A623), Color(0xFFFFCF77)],
        ),
      LightTemperature.neutral => const LinearGradient(
          colors: [Color(0xFFE8E0D0), Color(0xFFFFFFFF)],
        ),
      LightTemperature.cool => const LinearGradient(
          colors: [Color(0xFFA8C8E8), Color(0xFFD6EEFF)],
        ),
    };

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
      ),
    );
  }
}
