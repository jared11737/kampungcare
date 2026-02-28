import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// SOS countdown display with large digit, circular progress, and haptic per second.
/// Shows white-on-red countdown with animated circular progress indicator.
class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onComplete;

  const CountdownTimer({
    super.key,
    required this.seconds,
    required this.onComplete,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  late int _totalSeconds;
  Timer? _timer;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.seconds;
    _totalSeconds = widget.seconds;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
    _progressController.forward();

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onComplete();
        return;
      }

      HapticFeedback.heavyImpact();
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0
        ? _remainingSeconds / _totalSeconds
        : 0.0;

    return Semantics(
      label: 'Kira detik SOS: $_remainingSeconds saat lagi',
      liveRegion: true,
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: KampungCareTheme.urgentRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: KampungCareTheme.urgentRed.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            // Circular progress indicator
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            // Countdown number
            Text(
              '$_remainingSeconds',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
