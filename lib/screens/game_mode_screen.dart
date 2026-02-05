import 'package:flutter/material.dart';

import '../models/game_mode.dart';

class GameModeScreen extends StatelessWidget {
  const GameModeScreen({super.key, required this.onSelectGame});

  final void Function(GameMode mode) onSelectGame;

  static const _brandy = Color(0xFFD4A574);
  static const _surfaceHigh = Color(0xFF2C2520);
  static const _surfaceTop = Color(0xFF231C18);
  static const _onSurface = Color(0xFFEDE6DF);
  static const _onSurfaceVariant = Color(0xFFC4B5A4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1512),
      appBar: AppBar(
        title: const Text('🎮 Game mode', style: TextStyle(color: _onSurface)),
        backgroundColor: _surfaceTop,
        iconTheme: const IconThemeData(color: _brandy),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: GameMode.values.map((mode) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: _surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onSelectGame(mode);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _brandy.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconFor(mode),
                          color: _brandy,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mode.displayName,
                              style: const TextStyle(
                                color: _onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mode.subtitle,
                              style: const TextStyle(
                                color: _onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: _onSurfaceVariant, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(GameMode mode) {
    switch (mode) {
      case GameMode.twentyQuestions:
        return Icons.help_outline_rounded;
      case GameMode.guessTheWord:
        return Icons.text_fields_rounded;
      case GameMode.wouldYouRather:
        return Icons.balance_rounded;
    }
  }
}
