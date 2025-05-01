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

// Karakter listesi sağlayan sınıf (Bu kısım domain/repository veya data/datasource katmanına taşınabilir)
class CharacterManager {
  static final List<PlayerCharacter> _characters = [
    // Varsayılan karakter - Ninja (kılıçlı)
    PlayerCharacter(
      id: 'ninja',
      name: 'Ninja',
      price: 0,
      isUnlocked: true,
      primaryColor: Colors.black,
      secondaryColor: Colors.red.shade800,
      assetPath: 'assets/characters/ninja.png',
      attributes: {
        'jumpPower': 1.2,
        'speed': 1.2,
        'dashPower': 1.3,
        'coinMultiplier': 1.0,
        'weaponType': 'sword',
      },
    ),

    // Yeniçeri (kılıçlı)
    PlayerCharacter(
      id: 'janissary',
      name: 'Yeniçeri',
      price: 1500,
      isUnlocked: false,
      primaryColor: Colors.green.shade900,
      secondaryColor: Colors.red.shade700,
      assetPath: 'assets/characters/janissary.png',
      attributes: {
        'jumpPower': 1.0,
        'speed': 1.1,
        'dashPower': 1.0,
        'coinMultiplier': 1.2,
        'weaponType': 'sword',
      },
    ),

    // Viking (baltalı)
    PlayerCharacter(
      id: 'viking',
      name: 'Viking',
      price: 2000,
      isUnlocked: false,
      primaryColor: Colors.brown.shade800,
      secondaryColor: Colors.grey.shade400,
      assetPath: 'assets/characters/viking.png',
      attributes: {
        'jumpPower': 0.9,
        'speed': 0.9,
        'dashPower': 0.9,
        'coinMultiplier': 1.0,
        'weaponType': 'axe',
        'damage': 1.5, // Balta daha fazla hasar verir
      },
    ),

    // Kızılderili (okçu)
    PlayerCharacter(
      id: 'indian',
      name: 'Kızılderili',
      price: 3000,
      isUnlocked: false,
      primaryColor: Colors.brown.shade600,
      secondaryColor: Colors.red.shade500,
      assetPath: 'assets/characters/indian.png',
      attributes: {
        'jumpPower': 1.2,
        'speed': 1.1,
        'dashPower': 1.0,
        'coinMultiplier': 1.0,
        'weaponType': 'bow',
        'range': 1.5, // Ok daha uzağa gider
      },
    ),
  ];

  // Tüm karakterleri döndür
  static List<PlayerCharacter> get characters => _characters;

  // ID'ye göre karakter getir
  static PlayerCharacter getCharacterById(String id) {
    return _characters.firstWhere(
      (character) => character.id == id,
      orElse: () => _characters.first, // Varsayılan karakteri döndür
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
          character.id == 'ninja'; // Ninja varsayılan olarak açık
      result.add(character.copyWith(isUnlocked: isUnlocked));
    }

    return result;
  }
}
