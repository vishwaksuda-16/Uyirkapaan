import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/location_formatter.dart';
import '../../domain/entities/location_data.dart';
import '../controllers/location_controller.dart';

/// Card showing current GPS detection status, coordinates, accuracy, and adjust action.
class LocationCard extends StatelessWidget {
  final LocationController locationController;
  final VoidCallback onAdjustLocation;

  const LocationCard({
    super.key,
    required this.locationController,
    required this.onAdjustLocation,
  });

  @override
  Widget build(BuildContext context) {
    final LocationData? loc = locationController.emergencyLocation;
    final isManual = locationController.isManualOverride;
    final status = locationController.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (status == LocationFetchStatus.success || isManual)
                        ? AppColors.gpsActive.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isManual ? Icons.edit_location_rounded : Icons.my_location_rounded,
                    size: 20,
                    color: (status == LocationFetchStatus.success || isManual)
                        ? AppColors.gpsActive
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isManual ? 'Emergency Incident Location (Adjusted)' : 'Current Emergency Location',
                        style: AppTextStyles.sectionHeader.copyWith(fontSize: 14),
                      ),
                      Text(
                        status == LocationFetchStatus.loading
                            ? 'Acquiring GPS fix...'
                            : (status == LocationFetchStatus.success
                                ? '✓ GPS Lock Established'
                                : (isManual ? '✓ Manually Selected Pinpoint' : 'Using Fallback Location')),
                        style: TextStyle(
                          fontSize: 12,
                          color: (status == LocationFetchStatus.success || isManual)
                              ? AppColors.gpsActive
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdjustLocation,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Adjust'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.emergencyRed,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (loc != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('COORDINATES', style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Text(
                        LocationFormatter.formatCoordinates(loc.latitude, loc.longitude),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('ACCURACY', style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Text(
                        LocationFormatter.formatAccuracy(loc.accuracy),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Waiting for device coordinates...',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
