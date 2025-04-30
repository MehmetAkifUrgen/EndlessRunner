import 'package:flutter/material.dart';

enum WeaponType {
  pistol,
  shotgun,
  rifle,
  laserGun,
}

class Weapon {
  final WeaponType type;
  final String name;
  final double damage;
  final double
      fireRate; // Atış hızı - Saniyede kaç atış (1.0 = saniyede 1 atış)
  final int ammoCapacity; // Maksimum mermi kapasitesi
  final double reloadTime; // Yeniden dolum süresi (saniye)
  final Color bulletColor;
  final double bulletSize;
  final double bulletSpeed;
  final String assetPath;

  const Weapon({
    required this.type,
    required this.name,
    required this.damage,
    required this.fireRate,
    required this.ammoCapacity,
    required this.reloadTime,
    required this.bulletColor,
    required this.bulletSize,
    required this.bulletSpeed,
    required this.assetPath,
  });

  // Fabrika metodu - Belirli silah tipine göre silah oluşturur
  factory Weapon.fromType(WeaponType type) {
    switch (type) {
      case WeaponType.pistol:
        return Weapon(
          type: type,
          name: 'Tabanca',
          damage: 1.0,
          fireRate: 2.0,
          ammoCapacity: 12,
          reloadTime: 1.0,
          bulletColor: Colors.yellow,
          bulletSize: 8.0,
          bulletSpeed: 600.0,
          assetPath: 'assets/images/pistol.png',
        );

      case WeaponType.shotgun:
        return Weapon(
          type: type,
          name: 'Pompalı',
          damage: 3.0,
          fireRate: 0.8,
          ammoCapacity: 6,
          reloadTime: 1.5,
          bulletColor: Colors.orange,
          bulletSize: 6.0,
          bulletSpeed: 500.0,
          assetPath: 'assets/images/shotgun.png',
        );

      case WeaponType.rifle:
        return Weapon(
          type: type,
          name: 'Tüfek',
          damage: 1.5,
          fireRate: 5.0,
          ammoCapacity: 30,
          reloadTime: 2.0,
          bulletColor: Colors.red,
          bulletSize: 7.0,
          bulletSpeed: 700.0,
          assetPath: 'assets/images/rifle.png',
        );

      case WeaponType.laserGun:
        return Weapon(
          type: type,
          name: 'Lazer Silahı',
          damage: 2.0,
          fireRate: 3.0,
          ammoCapacity: 20,
          reloadTime: 1.8,
          bulletColor: Colors.blue,
          bulletSize: 10.0,
          bulletSpeed: 800.0,
          assetPath: 'assets/images/laser_gun.png',
        );
    }
  }
}

class Bullet {
  final double damage;
  final double speed;
  final double size;
  final Color color;
  final bool isPenetrating; // Düşmanları delip geçebilir mi
  final bool isExplosive; // Vurduğunda patlama efekti yaratır mı
  final double explosionRadius; // Patlama yarıçapı (isExplosive=true ise)

  const Bullet({
    required this.damage,
    required this.speed,
    required this.size,
    required this.color,
    this.isPenetrating = false,
    this.isExplosive = false,
    this.explosionRadius = 0.0,
  });

  // Silahtan mermi oluştur
  factory Bullet.fromWeapon(Weapon weapon, {bool isPowered = false}) {
    // Güçlendirilmiş mi kontrol et (güç-yükseltme etkisi altında)
    final damageMult = isPowered ? 2.0 : 1.0;
    final sizeMult = isPowered ? 1.5 : 1.0;
    final colorMod = isPowered ? 0.5 : 0.0; // Renk değişimi

    switch (weapon.type) {
      case WeaponType.pistol:
        return Bullet(
          damage: weapon.damage * damageMult,
          speed: weapon.bulletSpeed,
          size: weapon.bulletSize * sizeMult,
          color: Color.lerp(weapon.bulletColor, Colors.white, colorMod)!,
        );

      case WeaponType.shotgun:
        return Bullet(
          damage: weapon.damage * damageMult,
          speed: weapon.bulletSpeed,
          size: weapon.bulletSize * sizeMult,
          color: Color.lerp(weapon.bulletColor, Colors.white, colorMod)!,
          isExplosive: true,
          explosionRadius: 30.0,
        );

      case WeaponType.rifle:
        return Bullet(
          damage: weapon.damage * damageMult,
          speed: weapon.bulletSpeed,
          size: weapon.bulletSize * sizeMult,
          color: Color.lerp(weapon.bulletColor, Colors.white, colorMod)!,
          isPenetrating: true,
        );

      case WeaponType.laserGun:
        return Bullet(
          damage: weapon.damage * damageMult,
          speed: weapon.bulletSpeed,
          size: weapon.bulletSize * sizeMult,
          color: Color.lerp(weapon.bulletColor, Colors.white, colorMod)!,
          isPenetrating: true,
          isExplosive: isPowered,
          explosionRadius: isPowered ? 40.0 : 0.0,
        );
    }
  }
}

class AmmoSystem {
  final int maxAmmo;
  int currentAmmo;
  final int ammoPerPickup;

  AmmoSystem({
    this.maxAmmo = 50,
    int? startingAmmo,
    this.ammoPerPickup = 10,
  }) : currentAmmo = startingAmmo ?? maxAmmo ~/ 2;

  bool canShoot() {
    return currentAmmo > 0;
  }

  bool shoot() {
    if (canShoot()) {
      currentAmmo--;
      return true;
    }
    return false;
  }

  void pickup() {
    currentAmmo = (currentAmmo + ammoPerPickup).clamp(0, maxAmmo);
  }

  void reload(int amount) {
    currentAmmo = (currentAmmo + amount).clamp(0, maxAmmo);
  }
}
