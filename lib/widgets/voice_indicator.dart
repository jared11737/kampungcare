import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Animated microphone/speaker indicator with pulsating circle.
/// Shows a smooth sine-wave-like pulse animation when active.
class VoiceIndicator extends StatefulWidget {
  final bool isActive;
  final String type; // 'mic' or 'speaker'
  final double size;

  const VoiceIndicator({
    super.key,
    required this.isActive,
    this.type = 'mic',
    this.size = 60,
  });

  @override
  State<VoiceIndicator> createState() => _VoiceIndicatorState();
}

class _VoiceIndicatorState extends State<VoiceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Smooth sine-wave-like pulse: scale 1.0 to 1.2
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    return widget.type == 'mic' ? Icons.mic : Icons.volume_up;
  }

  String get _semanticsLabel {
    final device = widget.type == 'mic' ? 'Mikrofon' : 'Pembesar suara';
    final state = widget.isActive ? 'aktif' : 'tidak aktif';
    return '$device $state';
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isActive ? KampungCareTheme.calmBlue : Colors.grey.shade400;

    return Semantics(
      label: _semanticsLabel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale =
              widget.isActive ? _scaleAnimation.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 3,
                ),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                _icon,
                size: widget.size * 0.5,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}
