import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:math' as math;

enum EnemyType {
  basic,
  zombie,
  robot,
  monster,
  boss,
}

enum AttackType {
  melee,
  ranged,
  magic,
  none,
}

class Enemy {
  final EnemyType type;
  final double speed;
  final bool canFly;
  final bool canJump;
  final int pointValue;
  final AttackType attackType;
  final double attackRange;
  final double attackCooldown;
  final double attackDamage;
  final double size; // Düşman boyutu
  final int ammoDropChance;
  int health;
  int maxHealth;
  bool isAggressive;
  double detectionRange;

  Enemy({
    this.type = EnemyType.basic,
    this.speed = 1.0,
    this.health = 1,
    this.canFly = false,
    this.canJump = false,
    this.pointValue = 10,
    this.attackType = AttackType.none,
    this.attackRange = 0,
    this.attackCooldown = 1.0,
    this.attackDamage = 1.0,
    this.size = 50.0, // Varsayılan boyut
    this.ammoDropChance = 30,
    this.isAggressive = true,
    this.detectionRange = 300,
    int? maxHealth,
  }) : maxHealth = maxHealth ?? health;

  bool get isDead => health <= 0;

  void takeDamage(int damage) {
    health = math.max(0, health - damage);
  }

  void heal(int amount) {
    health = math.min(maxHealth, health + amount);
  }

  // Rastgele düşman oluştur
  static Enemy random() {
    final rnd = math.Random();

    // Rastgele düşman tipi seç
    final types = EnemyType.values.where((t) => t != EnemyType.boss).toList();
    final type = types[rnd.nextInt(types.length)];

    // Tipe göre özellikleri ayarla
    int health;
    int points;
    bool canFly;
    bool canJump;
    double speed;
    AttackType attackType;
    double attackRange;
    double attackCooldown;
    double attackDamage;
    bool isAggressive;
    double detectionRange;
    double size;
    int ammoDropChance;

    switch (type) {
      case EnemyType.zombie:
        health = 2;
        points = 15;
        canFly = false;
        canJump = true;
        speed = 0.8;
        attackType = AttackType.melee;
        attackRange = 50;
        attackCooldown = 2.0;
        attackDamage = 1.0;
        isAggressive = true;
        detectionRange = 250;
        size = 60.0;
        ammoDropChance = 20;
        break;
      case EnemyType.robot:
        health = 3;
        points = 20;
        canFly = false;
        canJump = false;
        speed = 1.0;
        attackType = rnd.nextBool() ? AttackType.melee : AttackType.ranged;
        attackRange = attackType == AttackType.ranged ? 200 : 60;
        attackCooldown = attackType == AttackType.ranged ? 3.0 : 1.5;
        attackDamage = 1.5;
        isAggressive = true;
        detectionRange = 350;
        size = 65.0;
        ammoDropChance = 50;
        break;
      case EnemyType.monster:
        health = 3;
        points = 25;
        canFly = rnd.nextBool(); // Bazı canavarlar uçabilir
        canJump = !canFly && rnd.nextBool(); // Uçmuyorsa zıplayabilir
        speed = canFly ? 1.2 : 0.9;
        attackType = rnd.nextInt(3) == 0 ? AttackType.magic : AttackType.melee;
        attackRange = attackType == AttackType.magic ? 180 : 70;
        attackCooldown = attackType == AttackType.magic ? 4.0 : 1.8;
        attackDamage = 2.0;
        isAggressive = true;
        detectionRange = 300;
        size = 70.0;
        ammoDropChance = 35;
        break;
      default:
        health = 1;
        points = 10;
        canFly = false;
        canJump = false;
        speed = 1.0;
        attackType = AttackType.none;
        attackRange = 0;
        attackCooldown = 0;
        attackDamage = 0;
        isAggressive = rnd.nextBool();
        detectionRange = 200;
        size = 50.0;
        ammoDropChance = 10;
    }

    return Enemy(
      type: type,
      health: health,
      pointValue: points,
      canFly: canFly,
      canJump: canJump,
      speed: speed,
      attackType: attackType,
      attackRange: attackRange,
      attackCooldown: attackCooldown,
      attackDamage: attackDamage,
      isAggressive: isAggressive,
      detectionRange: detectionRange,
      size: size,
      ammoDropChance: ammoDropChance,
    );
  }

  static Enemy createBoss() {
    return Enemy(
      type: EnemyType.boss,
      health: 10,
      maxHealth: 20,
      pointValue: 100,
      canFly: false,
      canJump: true,
      speed: 0.7,
      attackType: AttackType.magic,
      attackRange: 250,
      attackCooldown: 5.0,
      attackDamage: 3.0,
      isAggressive: true,
      detectionRange: 400,
      size: 120.0, // Boss daha büyük
      ammoDropChance: 100, // Boss her zaman mermi düşürür
    );
  }

  // Seviye ID'sine göre rastgele düşman oluştur
  static Enemy createRandomEnemy(int levelId) {
    final rnd = math.Random();
    final Enemy enemy = random();

    // Seviye arttıkça düşmanları güçlendir
    final levelMultiplier =
        1.0 + (levelId - 1) * 0.2; // Her seviye %20 daha güçlü

    // Boss düşmanı oluşturma olasılığı (seviye arttıkça artar)
    final bossChance = levelId * 0.01; // Her seviye %1 ihtimal
    if (rnd.nextDouble() < bossChance) {
      return createBoss();
    }

    // Düşman özelliklerini seviyeye göre ayarla
    return Enemy(
      type: enemy.type,
      health: (enemy.health * levelMultiplier).ceil(),
      maxHealth: (enemy.maxHealth * levelMultiplier).ceil(),
      pointValue: (enemy.pointValue * levelMultiplier).ceil(),
      canFly: enemy.canFly,
      canJump: enemy.canJump,
      speed: enemy.speed *
          math.min(1.5, levelMultiplier), // En fazla %50 hız artışı
      attackType: enemy.attackType,
      attackRange: enemy.attackRange *
          math.min(1.3, levelMultiplier), // En fazla %30 menzil artışı
      attackCooldown: enemy.attackCooldown /
          math.min(
              1.2, levelMultiplier), // Daha hızlı saldırı (en fazla %20 azalma)
      attackDamage: enemy.attackDamage * levelMultiplier,
      isAggressive:
          enemy.isAggressive || levelId > 2, // Seviye 2'den sonra hepsi agresif
      detectionRange: enemy.detectionRange *
          math.min(
              1.2, levelMultiplier), // En fazla %20 algılama menzili artışı
      size: enemy.size *
          math.min(1.3, levelMultiplier), // En fazla %30 boyut artışı
      ammoDropChance: math.min(
          100,
          (enemy.ammoDropChance * levelMultiplier)
              .ceil()), // En fazla %100 mermi düşürme şansı
    );
  }
}
