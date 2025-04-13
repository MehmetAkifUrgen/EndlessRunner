import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/character.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  _CharacterScreenState createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  @override
  Widget build(BuildContext context) {
    // Ekran boyutunu al
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // UI için sabitler
    final itemWidth = isSmallScreen ? screenSize.width * 0.8 : 400.0;
    final fontSize = isSmallScreen ? 16.0 : 18.0;
    final paddingSize = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? 24.0 : 28.0;

    // GameState'i al
    final gameState = Provider.of<GameState>(context);
    final characters = gameState.availableCharacters;
    final coins = gameState.coins;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gameState.currentTheme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar: Başlık ve geri butonu
              Padding(
                padding: EdgeInsets.all(paddingSize),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'CHARACTERS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 3.0,
                              color: Colors.black45,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Mevcut altın sayısını göster
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: iconSize,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$coins',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ana içerik: Karakter listesi
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(paddingSize),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final isSelected =
                        character.id == gameState.currentCharacterId;
                    final isUnlocked = character.isUnlocked;

                    return Padding(
                      padding: EdgeInsets.only(bottom: paddingSize),
                      child: Container(
                        width: itemWidth,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amber
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (isUnlocked) {
                                  // Karakteri seç
                                  gameState.setCurrentCharacter(character.id);
                                } else {
                                  // Satın alma diyaloğu göster
                                  _showBuyDialog(context, character, gameState);
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.all(paddingSize),
                                child: Row(
                                  children: [
                                    // Karakter avatarı (gölgeli kutu ile)
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: isUnlocked
                                            ? character.primaryColor
                                            : Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color: character.secondaryColor,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Karakter bilgileri
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                character.name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: fontSize + 4,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (isSelected)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8),
                                                  child: Icon(
                                                    Icons.check_circle,
                                                    color: Colors.amber,
                                                    size: iconSize,
                                                  ),
                                                ),
                                            ],
                                          ),

                                          const SizedBox(height: 8),

                                          // Karakter özellikleri
                                          if (isUnlocked)
                                            _buildStatBars(character, fontSize),

                                          // Kilitli karakter için fiyat
                                          if (!isUnlocked)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.lock,
                                                  color: Colors.white70,
                                                  size: iconSize,
                                                ),
                                                const SizedBox(width: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.monetization_on,
                                                      color: Colors.amber,
                                                      size: iconSize - 4,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${character.price}',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: fontSize,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Karakter özellik çubuklarını oluştur
  Widget _buildStatBars(PlayerCharacter character, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatBar('Jump', character.attributes['jumpPower'] ?? 1.0,
            Colors.green, fontSize - 2),
        const SizedBox(height: 4),
        _buildStatBar('Speed', character.attributes['speed'] ?? 1.0, Colors.blue,
            fontSize - 2),
        const SizedBox(height: 4),
        _buildStatBar('Dash', character.attributes['dashPower'] ?? 1.0,
            Colors.purple, fontSize - 2),
        if (character.attributes.containsKey('coinBonus')) ...[
          const SizedBox(height: 4),
          _buildStatBar('Coin Bonus', character.attributes['coinBonus'],
              Colors.amber, fontSize - 2),
        ],
      ],
    );
  }

  // Tek bir özellik çubuğu oluştur
  Widget _buildStatBar(
      String label, double value, Color color, double fontSize) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: fontSize,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              // Arka plan çubuk
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Değer çubuğu
              FractionallySizedBox(
                widthFactor: value.clamp(0.0, 2.0) /
                    2.0, // Maksimum 2.0 değeri için 0.0-1.0 arası
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Satın alma diyaloğu
  void _showBuyDialog(
      BuildContext context, PlayerCharacter character, GameState gameState) {
    final canBuy = gameState.coins >= character.price;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Buy ${character.name} Character',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to buy this character for ${character.price} coins?',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatBars(character, 14), // Özellik çubuklarını göster
            const SizedBox(height: 16),
            if (!canBuy)
              const Text(
                'Not enough coins!',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: canBuy
                ? () {
                    // Satın al
                    final success = gameState.buyCharacter(character.id);
                    Navigator.pop(context);

                    if (success) {
                      // Satın alma başarılı mesajı
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${character.name} character purchased!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              disabledBackgroundColor: Colors.grey,
            ),
            child: const Text(
              'BUY',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
