import 'dart:async';

import 'package:flutter/material.dart';

/// Typing indicator with bouncing dots and rotating personality phrases.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.brandy = const Color(0xFFD4A574),
    this.onSurfaceVariant = const Color(0xFFC4B5A4),
  });

  final Color brandy;
  final Color onSurfaceVariant;

  static const _phrases = [
    'Thinking...',
    'On it...',
    'One sec...',
    'Crafting a reply...',
    'Almost there...',
    'Let me think...',
  ];

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  Timer? _phraseTimer;
  int _phraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
    _phraseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _phraseIndex = (_phraseIndex + 1) % TypingIndicator._phrases.length);
    });
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _dotsController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.2;
                final t = ((_dotsController.value + delay) % 1.0);
                final y = 1.0 - (Curves.easeInOut.transform(t) * 2 - 1).abs();
                final offset = -4 * y;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.translate(
                    offset: Offset(0, offset),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.brandy.withOpacity(0.5 + 0.5 * y),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            TypingIndicator._phrases[_phraseIndex],
            key: ValueKey<int>(_phraseIndex),
            style: TextStyle(
              color: widget.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
