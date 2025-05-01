import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'game_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      body: GameWidget.controlled(
        initialActiveOverlays: const ['pause_button', 'game_controls'],
        gameFactory: () => RunnerGame(
          selectedCharacter: gameState.currentCharacter,
          currentTheme: gameState.currentTheme,
          currentLevel: gameState.currentLevel,
          highScore: gameState.highScore,
        ),
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        overlayBuilderMap: {
          'pause_button': (context, RunnerGame runnerGame) {
            return Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.pause, color: Colors.white),
                onPressed: () {
                  runnerGame.isPaused
                      ? runnerGame.resumeGame()
                      : runnerGame.pauseGame();
                },
              ),
            );
          },
          'game_controls': (context, RunnerGame runnerGame) {
            final screenSize = MediaQuery.of(context).size;
            return Stack(
              children: [
                // Zıplama için sol yarıya tıklama algılayıcı
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: screenSize.width / 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      runnerGame.playerJump();
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Ateş etme butonu (ekranın sağ tarafında ortalanmış)
                Positioned(
                  right: 30,
                  bottom: screenSize.height * 0.5 - 60,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Colors.red.shade400, Colors.red.shade800],
                        center: Alignment.center,
                        radius: 0.8,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: CircleBorder(),
                        splashColor: Colors.red.withOpacity(0.5),
                        onTap: () {
                          runnerGame.humanPlayer?.shoot();
                        },
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 80,
                                color: Colors.yellow.shade600,
                              ),
                              Icon(
                                Icons.local_fire_department,
                                size: 60,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          'game_over': (context, RunnerGame runnerGame) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GAME OVER',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Score: ${runnerGame.score}',
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'High Score: ${runnerGame.highScore}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      runnerGame.restartGame();
                    },
                    child: const Text(
                      'PLAY AGAIN',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'BACK TO MENU',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            );
          },
        },
      ),
    );
  }
}
