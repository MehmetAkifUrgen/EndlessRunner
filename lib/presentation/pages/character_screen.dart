import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../domain/entities/character.dart';
import 'dart:math' as math;

// TODO: Karakter seçim ekranının içeriğini buraya ekleyin.
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karakter Seç'),
        backgroundColor: Colors.teal,
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          final characters = gameState.availableCharacters;
          final selectedCharacterId = gameState.currentCharacter?.id ?? '';
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Savaşçını Seç',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final isSelected = character.id == selectedCharacterId;
                    final isLocked = !character.isUnlocked;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: isSelected ? 8 : 2,
                      color: isSelected
                          ? Colors.teal.shade100
                          : isLocked
                              ? Colors.grey.shade200
                              : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? BorderSide(color: Colors.teal.shade800, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: isLocked
                            ? () =>
                                _showUnlockDialog(context, character, gameState)
                            : () {
                                gameState.setCurrentCharacter(character.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${character.name} karakteri seçildi'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Karakter görseli (Avatar)
                              _buildCharacterAvatar(character, isLocked),

                              const SizedBox(width: 16),

                              // Karakter bilgileri
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
        child: Text(
                                            character.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isLocked)
                                          Row(
                                            children: [
                                              Icon(Icons.lock,
                                                  color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${character.price}',
                                                style: TextStyle(
                                                  color: Colors.amber.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.monetization_on,
                                                  color: Colors.amber.shade600,
                                                  size: 16),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Karakter özellikleri
                                    _buildCharacterAttributes(character),

                                    const SizedBox(height: 8),
                                    // Silah türü
                                    _buildWeaponTypeInfo(character),
                                  ],
                                ),
                              ),

                              // Seçili işareti veya kilitleri buton
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.teal.shade800,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                )
                              else if (isLocked)
                                ElevatedButton(
                                  onPressed: () => _showUnlockDialog(
                                      context, character, gameState),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Satın Al'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCharacterAvatar(PlayerCharacter character, bool isLocked) {
    // Karakter tipine göre avatarı oluştur
    Widget characterIcon;

    switch (character.id) {
      case 'ninja':
        characterIcon = _buildNinjaAvatar(character);
        break;
      case 'janissary':
        characterIcon = _buildJanissaryAvatar(character);
        break;
      case 'viking':
        characterIcon = _buildVikingAvatar(character);
        break;
      case 'indian':
        characterIcon = _buildIndianAvatar(character);
        break;
      default:
        characterIcon = _buildDefaultAvatar(character);
    }

    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: character.primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: characterIcon,
          ),
        ),
        if (isLocked)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.lock,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNinjaAvatar(PlayerCharacter character) {
    return Icon(
      Icons.person,
      size: 60,
      color: character.primaryColor,
    );
  }

  Widget _buildJanissaryAvatar(PlayerCharacter character) {
    return Icon(
      Icons.shield,
      size: 60,
      color: character.primaryColor,
    );
  }

  Widget _buildVikingAvatar(PlayerCharacter character) {
    return Icon(
      Icons.sports_kabaddi,
      size: 60,
      color: character.primaryColor,
    );
  }

  Widget _buildIndianAvatar(PlayerCharacter character) {
    return Transform.rotate(
      angle: -math.pi / 4,
      child: Icon(
        Icons.arrow_forward,
        size: 60,
        color: character.primaryColor,
      ),
    );
  }

  Widget _buildDefaultAvatar(PlayerCharacter character) {
    return Icon(
      Icons.face,
      size: 60,
      color: character.primaryColor,
    );
  }

  Widget _buildCharacterAttributes(PlayerCharacter character) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAttributeItem(
          icon: Icons.speed,
          value: character.attributes['speed'] ?? 1.0,
          label: 'Hız',
        ),
        _buildAttributeItem(
          icon: Icons.trending_up,
          value: character.attributes['jumpPower'] ?? 1.0,
          label: 'Zıplama',
        ),
        _buildAttributeItem(
          icon: Icons.bolt,
          value: character.attributes['dashPower'] ?? 1.0,
          label: 'Dash',
        ),
      ],
    );
  }

  Widget _buildAttributeItem({
    required IconData icon,
    required double value,
    required String label,
  }) {
    final filledBars = (value * 5).round();
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.teal.shade700),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            5,
            (index) => Container(
              width: 6,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: index < filledBars
                    ? Colors.teal.shade700
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildWeaponTypeInfo(PlayerCharacter character) {
    final weaponType =
        character.attributes['weaponType'] as String? ?? 'unknown';

    IconData weaponIcon;
    String weaponName;

    switch (weaponType) {
      case 'sword':
        weaponIcon = Icons.adobe;
        weaponName = 'Kılıç';
        break;
      case 'axe':
        weaponIcon = Icons.savings;
        weaponName = 'Balta';
        break;
      case 'bow':
        weaponIcon = Icons.expand_more;
        weaponName = 'Ok';
        break;
      default:
        weaponIcon = Icons.help_outline;
        weaponName = 'Bilinmeyen Silah';
    }

    return Row(
      children: [
        Icon(
          weaponIcon,
          size: 16,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 4),
        Text(
          weaponName,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (character.attributes['damage'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                Icon(Icons.flash_on, size: 16, color: Colors.red.shade700),
                Text(
                  '+${(character.attributes['damage'] - 1.0) * 100}%',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        if (character.attributes['range'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                Icon(Icons.arrow_outward,
                    size: 16, color: Colors.blue.shade700),
                Text(
                  '+${(character.attributes['range'] - 1.0) * 100}%',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showUnlockDialog(
      BuildContext context, PlayerCharacter character, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${character.name} Satın Al'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu karakteri satın almak istiyor musun?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${character.price}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.monetization_on, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Mevcut Altın: ${gameState.coins}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: gameState.coins >= character.price
                ? () {
                    gameState.unlockCharacter(character.id, character.price);
                    Navigator.pop(context);
                    // Başarılı satın alma mesajı
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('${character.name} başarıyla satın alındı!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                : null, // Yeterli altın yoksa buton devre dışı
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('Satın Al'),
          ),
        ],
      ),
    );
  }
}
