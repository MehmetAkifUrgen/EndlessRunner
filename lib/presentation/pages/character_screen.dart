import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../domain/entities/character.dart';
import 'dart:math' as math;

// TODO: Add character selection screen content here.
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Characters',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(150, 0, 0, 0),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.indigo.shade600,
            ],
          ),
        ),
        child: Consumer<GameState>(
          builder: (context, gameState, child) {
            final characters = gameState.availableCharacters;
            final selectedCharacterId = gameState.currentCharacter?.id ?? '';
            return Column(
              children: [
                const SizedBox(height: kToolbarHeight + 20),
                _buildHeader(context, gameState),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      final character = characters[index];
                      final isSelected = character.id == selectedCharacterId;
                      final isLocked = !character.isUnlocked;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Colors.yellow.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.2),
                              blurRadius: isSelected ? 10 : 5,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: isSelected
                              ? Colors.white
                              : isLocked
                                  ? Colors.grey.shade200
                                  : Colors.white.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isSelected
                                ? BorderSide(
                                    color: Colors.yellow.shade600, width: 3)
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: isLocked
                                ? () => _showUnlockDialog(
                                    context, character, gameState)
                                : () {
                                    gameState.setCurrentCharacter(character.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${character.name} character selected',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: Colors.green.shade700,
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Character image (Avatar)
                                      _buildCharacterAvatar(
                                          character, isLocked),

                                      const SizedBox(width: 16),

                                      // Character information
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    character.name,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isLocked
                                                          ? Colors.grey.shade600
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                if (isLocked)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.amber.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          '${character.price}',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .amber.shade800,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Icon(
                                                          Icons.monetization_on,
                                                          color: Colors
                                                              .amber.shade600,
                                                          size: 16,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            // Weapon type
                                            _buildWeaponTypeInfo(character),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),

                                  // Character attributes
                                  _buildCharacterAttributes(
                                      character, isLocked),

                                  const SizedBox(height: 12),

                                  // Select/Buy buttons
                                  _buildActionButton(context, character,
                                      isSelected, isLocked, gameState),
                                ],
                              ),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GameState gameState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Warrior',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              Text(
                'Each warrior has unique abilities',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${gameState.coins}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterAvatar(PlayerCharacter character, bool isLocked) {
    // Create avatar based on character type
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
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                character.primaryColor.withOpacity(0.7),
                character.secondaryColor.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: character.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: characterIcon,
          ),
        ),
        if (isLocked)
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.lock,
                color: Colors.white.withOpacity(0.8),
                size: 40,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNinjaAvatar(PlayerCharacter character) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.sports_kabaddi,
            size: 18,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildJanissaryAvatar(PlayerCharacter character) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Transform.rotate(
            angle: math.pi / 4,
            child: Icon(
              Icons.airline_seat_flat,
              size: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVikingAvatar(PlayerCharacter character) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_kabaddi,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.format_list_numbered,
            size: 18,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildIndianAvatar(PlayerCharacter character) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 40,
            child: CustomPaint(
              painter: ArrowPainter(),
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.grain,
            size: 18,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(PlayerCharacter character) {
    return Icon(
      Icons.face,
      size: 60,
      color: Colors.white,
    );
  }

  Widget _buildCharacterAttributes(PlayerCharacter character, bool isLocked) {
    final textColor = isLocked ? Colors.grey.shade500 : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAttributeItem(
            icon: Icons.speed,
            value: character.attributes['speed'] ?? 1.0,
            label: 'Speed',
            textColor: textColor,
            isLocked: isLocked,
          ),
          _buildAttributeItem(
            icon: Icons.trending_up,
            value: character.attributes['jumpPower'] ?? 1.0,
            label: 'Jump',
            textColor: textColor,
            isLocked: isLocked,
          ),
          _buildAttributeItem(
            icon: Icons.bolt,
            value: character.attributes['dashPower'] ?? 1.0,
            label: 'Dash',
            textColor: textColor,
            isLocked: isLocked,
          ),
          _buildAttributeItem(
            icon: Icons.monetization_on,
            value: character.attributes['coinMultiplier'] ?? 1.0,
            label: 'Coins',
            textColor: textColor,
            isLocked: isLocked,
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeItem({
    required IconData icon,
    required double value,
    required String label,
    required Color textColor,
    required bool isLocked,
  }) {
    // Normalize values between 0.5 and 1.5 to a range of 1 to 5
    final normalizedValue = ((value - 0.5) * 10 / 2).clamp(1, 5).round();
    final valueColor = isLocked
        ? Colors.grey.shade400
        : value >= 1.2
            ? Colors.green
            : value >= 1.0
                ? Colors.amber.shade600
                : Colors.red;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < normalizedValue ? Icons.star : Icons.star_border,
              size: 14,
              color:
                  index < normalizedValue ? valueColor : Colors.grey.shade300,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWeaponTypeInfo(PlayerCharacter character) {
    final weaponType = character.attributes['weaponType'] as String? ?? 'sword';

    IconData weaponIcon;
    String weaponName;
    Color weaponColor;

    switch (weaponType) {
      case 'sword':
        weaponIcon = Icons.swap_horizontal_circle;
        weaponName = 'Sword';
        weaponColor = Colors.blue.shade700;
        break;
      case 'axe':
        weaponIcon = Icons.flash_on;
        weaponName = 'Axe';
        weaponColor = Colors.red.shade700;
        break;
      case 'bow':
        weaponIcon = Icons.arrow_forward;
        weaponName = 'Bow';
        weaponColor = Colors.green.shade700;
        break;
      default:
        weaponIcon = Icons.help_outline;
        weaponName = 'Unknown';
        weaponColor = Colors.grey;
    }

    // Weapon special abilities
    String specialAbility = '';
    if (weaponType == 'axe' && character.attributes.containsKey('damage')) {
      final damage = character.attributes['damage'] as double? ?? 1.0;
      specialAbility = 'Damage: +${((damage - 1.0) * 100).toInt()}%';
    } else if (weaponType == 'bow' &&
        character.attributes.containsKey('range')) {
      final range = character.attributes['range'] as double? ?? 1.0;
      specialAbility = 'Range: +${((range - 1.0) * 100).toInt()}%';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: weaponColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: weaponColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                weaponIcon,
                size: 16,
                color: weaponColor,
              ),
              const SizedBox(width: 4),
              Text(
                weaponName,
                style: TextStyle(
                  fontSize: 12,
                  color: weaponColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (specialAbility.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.5)),
            ),
            child: Text(
              specialAbility,
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, PlayerCharacter character,
      bool isSelected, bool isLocked, GameState gameState) {
    if (isSelected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade600,
              Colors.green.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'SELECTED',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    } else if (isLocked) {
      final canBuy = gameState.coins >= character.price;

      return ElevatedButton(
        onPressed: canBuy
            ? () => _showUnlockDialog(context, character, gameState)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canBuy ? Colors.amber.shade600 : Colors.grey.shade400,
          foregroundColor: Colors.white,
          elevation: canBuy ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canBuy ? Icons.lock_open : Icons.lock,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              canBuy ? 'BUY' : 'NOT ENOUGH COINS',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () {
          gameState.setCurrentCharacter(character.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${character.name} character selected',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'SELECT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showUnlockDialog(
      BuildContext context, PlayerCharacter character, GameState gameState) {
    final bool canBuy = gameState.coins >= character.price;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Buy ${character.name} Character',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCharacterAvatar(character, false),
            const SizedBox(height: 16),
            Text(
              'Price: ${character.price}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: canBuy ? Colors.amber.shade800 : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Balance: ${gameState.coins}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!canBuy) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You don\'t have enough coins to buy this character!',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: canBuy
                ? () {
                    gameState.unlockCharacter(character.id, character.price);
                    Navigator.pop(context);
                    // Successful purchase message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${character.name} successfully purchased!',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null, // Disable button if not enough coins
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              disabledBackgroundColor: Colors.grey.shade400,
              elevation: canBuy ? 2 : 0,
            ),
            child: const Text('BUY'),
          ),
        ],
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint arrowShaftPaint = Paint()
      ..color = Colors.brown.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final Paint arrowheadPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
      
    final Paint featherPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw arrow shaft
    final Path shaftPath = Path();
    shaftPath.moveTo(size.width * 0.1, size.height / 2);
    shaftPath.lineTo(size.width * 0.9, size.height / 2);
    canvas.drawPath(shaftPath, arrowShaftPaint);
    
    // Draw arrowhead
    final Path arrowheadPath = Path();
    arrowheadPath.moveTo(size.width * 0.9, size.height / 2);
    arrowheadPath.lineTo(size.width * 0.75, size.height * 0.2);
    arrowheadPath.lineTo(size.width * 0.9, size.height * 0.35);
    arrowheadPath.lineTo(size.width * 0.9, size.height * 0.65);
    arrowheadPath.lineTo(size.width * 0.75, size.height * 0.8);
    arrowheadPath.close();
    canvas.drawPath(arrowheadPath, arrowheadPaint);
    
    // Draw feathers
    for (int i = 0; i < 3; i++) {
      final double x = size.width * 0.2 + (i * size.width * 0.05);
      final Path featherPath = Path();
      featherPath.moveTo(x, size.height * 0.3);
      featherPath.lineTo(x, size.height * 0.7);
      canvas.drawPath(featherPath, featherPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
