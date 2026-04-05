import 'dart:math';
import 'package:flutter/material.dart';
import 'orbit_item.dart';
import 'floating_animation.dart';

class OrbitInterests extends StatelessWidget {
  const OrbitInterests({super.key});

  final List<String> interests = const [
    "Summer",
    "Flower",
    "Beret",
    "Music",
  ];

  @override
  Widget build(BuildContext context) {
    final double radius = 120;
    final int count = interests.length;

    return Stack(
      alignment: Alignment.center,
      children: List.generate(count, (index) {
        final angle = (2 * pi * index) / count;

        final x = radius * cos(angle);
        final y = radius * sin(angle);

        return Transform.translate(
          offset: Offset(x, y),
          child: FloatingAnimation(
            child: OrbitItem(label: interests[index]),
          ),
        );
      }),
    );
  }
}