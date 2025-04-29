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
    // Varsayılan karakter (ücretsiz)
    PlayerCharacter(
      id: 'rabbit',
      name: 'Tavşan',
      price: 0,
      isUnlocked: true,
      primaryColor: Colors.white,
      secondaryColor: Colors.grey.shade300,
      assetPath: 'assets/characters/rabbit.png',
      attributes: {
        'jumpPower': 1.0,
        'speed': 1.0,
        'dashPower': 1.0,
        'coinMultiplier': 1.0,
      },
    ),

    // Hızlı karakter
    PlayerCharacter(
      id: 'cheetah',
      name: 'Çita',
      price: 1000,
      isUnlocked: false,
      primaryColor: Colors.amber,
      secondaryColor: Colors.brown,
      assetPath: 'assets/characters/cheetah.png',
      attributes: {
        'jumpPower': 0.9,
        'speed': 1.3,
        'dashPower': 1.1,
        'coinMultiplier': 1.0,
      },
    ),

    // Yüksek zıplayıcı karakter
    PlayerCharacter(
      id: 'frog',
      name: 'Kurbağa',
      price: 1500,
      isUnlocked: false,
      primaryColor: Colors.green,
      secondaryColor: Colors.lightGreen,
      assetPath: 'assets/characters/frog.png',
      attributes: {
        'jumpPower': 1.5,
        'speed': 0.9,
        'dashPower': 0.9,
        'coinMultiplier': 1.0,
      },
    ),

    // Dash yeteneği yüksek karakter
    PlayerCharacter(
      id: 'fox',
      name: 'Tilki',
      price: 2000,
      isUnlocked: false,
      primaryColor: Colors.deepOrange,
      secondaryColor: Colors.orange,
      assetPath: 'assets/characters/fox.png',
      attributes: {
        'jumpPower': 1.0,
        'speed': 1.0,
        'dashPower': 1.5,
        'coinMultiplier': 1.1,
      },
    ),

    // VIP karakter
    PlayerCharacter(
      id: 'eagle',
      name: 'Kartal',
      price: 5000,
      isUnlocked: false,
      primaryColor: Colors.brown.shade800,
      secondaryColor: Colors.white,
      assetPath: 'assets/characters/eagle.png',
      attributes: {
        'jumpPower': 1.2,
        'speed': 1.2,
        'dashPower': 1.2,
        'coinMultiplier': 1.5,
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
          character.id == 'rabbit'; // Tavşan varsayılan olarak açık
      result.add(character.copyWith(isUnlocked: isUnlocked));
    }

    return result;
  }
}
