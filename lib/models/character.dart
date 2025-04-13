import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerCharacter {
  final String id;
  final String name;
  final int price;
  final bool isUnlocked;
  final Color primaryColor;
  final Color secondaryColor;
  final String? assetPath; // Görsel asset yolu (opsiyonel)
  final Map<String, dynamic> attributes; // Karakterin özellikleri

  PlayerCharacter({
    required this.id,
    required this.name,
    required this.price,
    this.isUnlocked = false,
    required this.primaryColor,
    required this.secondaryColor,
    this.assetPath,
    this.attributes = const {},
  });

  // Kopya oluştur ama bazı alanları değiştir
  PlayerCharacter copyWith({
    String? id,
    String? name,
    int? price,
    bool? isUnlocked,
    Color? primaryColor,
    Color? secondaryColor,
    String? assetPath,
    Map<String, dynamic>? attributes,
  }) {
    return PlayerCharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      assetPath: assetPath ?? this.assetPath,
      attributes: attributes ?? this.attributes,
    );
  }
}

// Karakter listesi sağlayan sınıf
class CharacterManager {
  static final List<PlayerCharacter> _characters = [
    // Varsayılan karakter (ücretsiz)
    PlayerCharacter(
      id: 'runner',
      name: 'Runner',
      price: 0,
      isUnlocked: true,
      primaryColor: Colors.red,
      secondaryColor: Colors.redAccent,
      attributes: {
        'jumpPower': 1.0,
        'speed': 1.0,
        'dashPower': 1.0,
      },
    ),

    // Hızlı koşucu
    PlayerCharacter(
      id: 'speedy',
      name: 'Speedy',
      price: 1000,
      primaryColor: Colors.blue,
      secondaryColor: Colors.lightBlue,
      attributes: {
        'jumpPower': 0.8,
        'speed': 1.2,
        'dashPower': 1.1,
      },
    ),

    // Zıplayan karakter
    PlayerCharacter(
      id: 'jumper',
      name: 'Jumper',
      price: 1500,
      primaryColor: Colors.green,
      secondaryColor: Colors.lightGreen,
      attributes: {
        'jumpPower': 1.3,
        'speed': 0.9,
        'dashPower': 0.9,
      },
    ),

    // Dash uzmanı
    PlayerCharacter(
      id: 'dasher',
      name: 'Dasher',
      price: 2000,
      primaryColor: Colors.purple,
      secondaryColor: Colors.purpleAccent,
      attributes: {
        'jumpPower': 0.9,
        'speed': 1.0,
        'dashPower': 1.4,
      },
    ),

    // VIP karakter
    PlayerCharacter(
      id: 'golden',
      name: 'Golden Runner',
      price: 5000,
      primaryColor: Colors.amber,
      secondaryColor: Colors.orange,
      attributes: {
        'jumpPower': 1.2,
        'speed': 1.2,
        'dashPower': 1.2,
        'coinBonus': 1.2, // Altın bonusu
      },
    ),
  ];

  // Tüm karakterleri döndür
  static List<PlayerCharacter> get characters => _characters;

  // ID'ye göre karakter getir
  static PlayerCharacter getCharacterById(String id) {
    return _characters.firstWhere(
      (character) => character.id == id,
      orElse: () => _characters.first,
    );
  }

  // Karakter kilidini aç
  static Future<void> unlockCharacter(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('character_$id', true);
  }

  // Karakter durumunu yükle
  static Future<List<PlayerCharacter>> loadCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    final List<PlayerCharacter> result = [];

    for (var character in _characters) {
      final isUnlocked = prefs.getBool('character_${character.id}') ??
          character.id == 'runner';
      result.add(character.copyWith(isUnlocked: isUnlocked));
    }

    return result;
  }
}
