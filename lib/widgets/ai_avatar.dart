import 'dart:math' as math;

import 'package:flutter/material.dart';

/// AI avatar that blinks periodically and changes expression (idle vs thinking).
class AiAvatar extends StatefulWidget {
  const AiAvatar({
    super.key,
    required this.isThinking,
    this.size = 36,
    this.brandy = const Color(0xFFD4A574),
    this.background = const Color(0xFF4A3728),
  });

  final bool isThinking;
  final double size;
  final Color brandy;
  final Color background;

  @override
  State<AiAvatar> createState() => _AiAvatarState();
}

class _AiAvatarState extends State<AiAvatar> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _expressionController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _expressionAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _expressionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expressionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _expressionController, curve: Curves.easeInOut),
    );

    _scheduleBlink();
  }

  void _scheduleBlink() {
    Future.delayed(Duration(seconds: 2 + math.Random().nextInt(4)), () {
      if (!mounted || !_blinkController.isAnimating) {
        _blinkController.forward().then((_) {
          if (mounted) _blinkController.reverse().then((_) => _scheduleBlink());
        });
      }
    });
  }

  @override
  void didUpdateWidget(AiAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isThinking != oldWidget.isThinking) {
      if (widget.isThinking) {
        _expressionController.forward();
      } else {
        _expressionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _expressionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(widget.size * 0.28),
        boxShadow: [
          BoxShadow(
            color: widget.brandy.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.28),
        child: AnimatedBuilder(
          animation: Listenable.merge([_blinkController, _expressionController]),
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _AvatarFacePainter(
                blink: _blinkAnimation.value,
                expression: _expressionAnimation.value,
                isThinking: widget.isThinking,
                color: widget.brandy,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AvatarFacePainter extends CustomPainter {
  _AvatarFacePainter({
    required this.blink,
    required this.expression,
    required this.isThinking,
    required this.color,
  });

  final double blink;
  final double expression;
  final bool isThinking;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final eyeY = cy - size.height * 0.12;
    final eyeSpacing = size.width * 0.22;
    final eyeW = size.width * 0.12;
    final eyeH = size.height * 0.08 * (1 - blink);
    final mouthY = cy + size.height * 0.18;

    final paint = Paint()..color = color;

    // Left eye
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - eyeSpacing, eyeY),
          width: eyeW,
          height: eyeH.clamp(2, 999),
        ),
        const Radius.circular(4),
      ),
      paint,
    );
    // Right eye
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + eyeSpacing, eyeY),
          width: eyeW,
          height: eyeH.clamp(2, 999),
        ),
        const Radius.circular(4),
      ),
      paint,
    );

    // Mouth: line when idle, slight curve when thinking
    final mouthPath = Path();
    final mouthW = size.width * (0.15 + 0.08 * expression);
    final mouthCurve = size.height * 0.03 * (isThinking ? 1 : 0);
    mouthPath.moveTo(cx - mouthW, mouthY);
    mouthPath.quadraticBezierTo(cx, mouthY + mouthCurve, cx + mouthW, mouthY);
    canvas.drawPath(mouthPath, paint..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_AvatarFacePainter old) =>
      blink != old.blink || expression != old.expression || isThinking != old.isThinking;
}
