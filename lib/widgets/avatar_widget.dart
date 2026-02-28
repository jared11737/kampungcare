import 'package:flutter/material.dart';
import '../config/theme.dart';

/// AI companion "Sayang" avatar with gentle pulsation when speaking.
/// Large circular container with calmBlue background and heart icon.
class AvatarWidget extends StatefulWidget {
  final double size;
  final bool isSpeaking;

  const AvatarWidget({
    super.key,
    this.size = 120,
    this.isSpeaking = false,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isSpeaking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSpeaking && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isSpeaking
          ? 'Sayang sedang bercakap'
          : 'Sayang, teman AI anda',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final scale =
                  widget.isSpeaking ? _scaleAnimation.value : 1.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: KampungCareTheme.calmBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KampungCareTheme.calmBlue.withValues(
                          alpha: widget.isSpeaking ? 0.5 : 0.25,
                        ),
                        blurRadius: widget.isSpeaking ? 24 : 12,
                        spreadRadius: widget.isSpeaking ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: widget.size * 0.5,
                    color: KampungCareTheme.textOnDark,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Sayang',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.calmBlue,
            ),
          ),
        ],
      ),
    );
  }
}
