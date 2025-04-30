import 'package:flutter/material.dart';
import 'dart:math';

enum PlatformType {
  normal,
  crumbling,
  moving,
  bouncy,
  hazardous,
}

class GamePlatform {
  final PlatformType type;
  final double width;
  final double height;
  final Color color;
  final bool isVisible;
  final double lifespan; // Özellikle crumbling platform için - saniyeler
  final double bounceForce; // bouncy platform için
  final double movementDistance; // moving platform için - ne kadar hareket eder
  final double movementSpeed; // moving platform için - hareket hızı
  final double damage; // hazardous platform için hasar miktarı

  const GamePlatform({
    required this.type,
    required this.width,
    required this.height,
    required this.color,
    this.isVisible = true,
    this.lifespan = 2.0,
    this.bounceForce = 1.5,
    this.movementDistance = 100.0,
    this.movementSpeed = 50.0,
    this.damage = 1.0,
  });

  // Fabrika metodu - Platform tipine göre örnekler oluşturur
  factory GamePlatform.fromType(PlatformType type, {double width = 100.0}) {
    switch (type) {
      case PlatformType.normal:
        return GamePlatform(
          type: type,
          width: width,
          height: 20.0,
          color: Colors.brown.shade700,
        );

      case PlatformType.crumbling:
        return GamePlatform(
          type: type,
          width: width,
          height: 15.0,
          color: Colors.brown.shade400,
          lifespan: 1.0, // 1 saniye sonra yok olur
        );

      case PlatformType.moving:
        return GamePlatform(
          type: type,
          width: width,
          height: 20.0,
          color: Colors.teal.shade700,
          movementDistance: width * 2, // Genişliğinin 2 katı kadar hareket eder
          movementSpeed: 60.0,
        );

      case PlatformType.bouncy:
        return GamePlatform(
          type: type,
          width: width,
          height: 15.0,
          color: Colors.blue.shade600,
          bounceForce: 1.8, // Normal zıplamanın 1.8 katı güç
        );

      case PlatformType.hazardous:
        return GamePlatform(
          type: type,
          width: width * 0.8, // Biraz daha dar
          height: 15.0,
          color: Colors.red.shade700,
          damage: 1.0, // 1 hasar verir
        );
    }
  }

  // Rastgele platform oluşturma (seviyeye göre)
  static GamePlatform randomPlatform(int level,
      {double minWidth = 80.0, double maxWidth = 200.0}) {
    final random = Random();

    // Platform genişliği rastgele olsun
    final width = minWidth + random.nextDouble() * (maxWidth - minWidth);

    // Mevcut tüm platform tipleri
    final availableTypes = <PlatformType>[];

    // Seviye 1: Sadece normal
    availableTypes.add(PlatformType.normal);

    // Seviye 2: Normal + Moving
    if (level >= 2) {
      availableTypes.add(PlatformType.moving);
    }

    // Seviye 3: Normal + Moving + Bouncy
    if (level >= 3) {
      availableTypes.add(PlatformType.bouncy);
    }

    // Seviye 4: Normal + Moving + Bouncy + Crumbling
    if (level >= 4) {
      availableTypes.add(PlatformType.crumbling);
    }

    // Seviye 5: Tüm tipler
    if (level >= 5) {
      availableTypes.add(PlatformType.hazardous);
    }

    // Zorluk seviyesine göre platform tipi seç
    final selectedType = availableTypes[random.nextInt(availableTypes.length)];
    return GamePlatform.fromType(selectedType, width: width);
  }
}
