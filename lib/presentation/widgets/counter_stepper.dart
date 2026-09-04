import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Accessible and responsive counter stepper for victim count selection.
class CounterStepper extends StatelessWidget {
  final int count;
  final int min;
  final int max;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CounterStepper({
    super.key,
    required this.count,
    required this.min,
    required this.max,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrement = count > min;
    final canIncrement = count < max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            onPressed: canDecrement ? onDecrement : null,
            icon: const Icon(Icons.remove_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: canDecrement
                  ? AppColors.emergencyLightRed
                  : theme.disabledColor.withValues(alpha: 0.1),
              foregroundColor: canDecrement
                  ? AppColors.emergencyDarkRed
                  : theme.disabledColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(52, 52),
            ),
          ),
          Column(
            children: [
              Text(
                '$count',
                style: AppTextStyles.metricValue.copyWith(
                  color: AppColors.emergencyRed,
                ),
              ),
              Text(
                count == 1 ? 'VICTIM' : 'VICTIMS',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          IconButton.filledTonal(
            onPressed: canIncrement ? onIncrement : null,
            icon: const Icon(Icons.add_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: canIncrement
                  ? AppColors.emergencyLightRed
                  : theme.disabledColor.withValues(alpha: 0.1),
              foregroundColor: canIncrement
                  ? AppColors.emergencyDarkRed
                  : theme.disabledColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(52, 52),
            ),
          ),
        ],
      ),
    );
  }
}
