// Silah tipleri
enum WeaponType { pistol, shotgun, rifle, laser, tripleShot, explosive }

// Silah özellikleri
class WeaponProperties {
  final double damage;
  final double fireRate;
  final int ammoCapacity;
  final double reloadTime;
  final List<String> specialEffects;

  const WeaponProperties({
    required this.damage,
    required this.fireRate,
    required this.ammoCapacity,
    required this.reloadTime,
    required this.specialEffects,
  });
}

// Özel ateş modları
class FireMode {
  final bool isTripleShot;
  final bool isBouncing;
  final bool isExplosive;
  final bool isPiercing;

  const FireMode({
    this.isTripleShot = false,
    this.isBouncing = false,
    this.isExplosive = false,
    this.isPiercing = false,
  });
}

class WeaponSystem {
  // WeaponSystem implementation here
}
