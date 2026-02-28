import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// 5-option mood picker for elderly users (fallback when STT fails).
/// Maps to 1-5 mood scale with Malay labels.
class MoodSelector extends StatefulWidget {
  final Function(int) onSelected;

  const MoodSelector({
    super.key,
    required this.onSelected,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  int? _selectedMood;

  static const List<_MoodOption> _moods = [
    _MoodOption(value: 1, emoji: '😢', label: 'Sangat\nSedih'),
    _MoodOption(value: 2, emoji: '😟', label: 'Sedih'),
    _MoodOption(value: 3, emoji: '😐', label: 'Biasa'),
    _MoodOption(value: 4, emoji: '🙂', label: 'Gembira'),
    _MoodOption(value: 5, emoji: '😊', label: 'Sangat\nGembira'),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pilih perasaan anda hari ini',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bagaimana perasaan anda?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: KampungCareTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _moods.map((mood) {
              final isSelected = _selectedMood == mood.value;
              return _buildMoodButton(mood, isSelected);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(_MoodOption mood, bool isSelected) {
    return Semantics(
      button: true,
      label: '${mood.label.replaceAll('\n', ' ')}, perasaan ${mood.value} daripada 5',
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _selectedMood = mood.value;
          });
          widget.onSelected(mood.value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? KampungCareTheme.primaryGreen.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? KampungCareTheme.primaryGreen
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.emoji,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 6),
              Text(
                mood.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? KampungCareTheme.primaryGreen
                      : KampungCareTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodOption {
  final int value;
  final String emoji;
  final String label;

  const _MoodOption({
    required this.value,
    required this.emoji,
    required this.label,
  });
}
