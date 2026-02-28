import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Status dot widget with optional label and pulsating animation for red status.
/// Maps 'green', 'yellow', 'red' to theme colors and Malay labels.
class StatusIndicator extends StatefulWidget {
  final String status; // 'green', 'yellow', 'red'
  final double size;
  final bool showLabel;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 24,
    this.showLabel = true,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.status == 'red') {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == 'red' && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.status != 'red' && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.status) {
      case 'green':
        return KampungCareTheme.primaryGreen;
      case 'yellow':
        return KampungCareTheme.warningAmber;
      case 'red':
        return KampungCareTheme.urgentRed;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (widget.status) {
      case 'green':
        return 'Semua Baik';
      case 'yellow':
        return 'Perlu Perhatian';
      case 'red':
        return 'Kecemasan';
      default:
        return '';
    }
  }

  String get _semanticsLabel {
    switch (widget.status) {
      case 'green':
        return 'Status: Semua Baik - Tiada masalah';
      case 'yellow':
        return 'Status: Perlu Perhatian - Amaran sederhana';
      case 'red':
        return 'Status: Kecemasan - Memerlukan tindakan segera';
      default:
        return 'Status tidak diketahui';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticsLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.status == 'red' ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.5),
                        blurRadius: widget.status == 'red' ? 12 : 4,
                        spreadRadius: widget.status == 'red' ? 2 : 0,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 10),
            Text(
              _label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
