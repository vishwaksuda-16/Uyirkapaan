import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/location_formatter.dart';
import '../../../domain/entities/tracking_info.dart';
import '../../../domain/repositories/tracking_repository.dart';
import '../../controllers/emergency_controller.dart';

/// Screen 6: Integration-Ready Live Tracking & ETA Screen.
/// Connects to TrackingRepository stream abstraction; prepared for Module 6 WebSocket wiring.
class TrackingPlaceholderScreen extends StatefulWidget {
  final EmergencyController emergencyController;
  final TrackingRepository trackingRepository;

  const TrackingPlaceholderScreen({
    super.key,
    required this.emergencyController,
    required this.trackingRepository,
  });

  @override
  State<TrackingPlaceholderScreen> createState() => _TrackingPlaceholderScreenState();
}

class _TrackingPlaceholderScreenState extends State<TrackingPlaceholderScreen> {
  TrackingInfo? _currentTelemetry;

  @override
  void initState() {
    super.initState();
    final active = widget.emergencyController.activeRequest;
    if (active != null) {
      widget.trackingRepository.getTrackingInfo(active.requestId).then((info) {
        if (mounted && info != null) {
          setState(() {
            _currentTelemetry = info;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRequest = widget.emergencyController.activeRequest;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Ambulance Tracking'),
      ),
      body: StreamBuilder<TrackingInfo>(
        stream: activeRequest != null
            ? widget.trackingRepository.watchTrackingUpdates(activeRequest.requestId)
            : const Stream.empty(),
        initialData: _currentTelemetry,
        builder: (context, snapshot) {
          final telemetry = snapshot.data ?? _currentTelemetry;
          final ambulanceId = telemetry?.ambulanceId ?? activeRequest?.assignedAmbulanceId ?? 'AMB-01';
          final etaFormatted = telemetry?.eta?.formattedEta ?? '6 min';
          final speed = telemetry?.speedKmH != null ? '${telemetry!.speedKmH!.toStringAsFixed(0)} km/h' : '--';

          return Column(
            children: [
              // Top Integration Notice Banner
              Container(
                width: double.infinity,
                color: AppColors.info.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  children: [
                    Icon(Icons.hub_rounded, color: AppColors.info, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MODULE 6 INTEGRATION READY: Telemetry hooked to TrackingRepository stream.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Map Canvas Placeholder Area
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFE5E3DF),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.statusEnRoute,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.statusEnRoute.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_car_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                ambulanceId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (telemetry != null)
                              Text(
                                LocationFormatter.formatCoordinates(telemetry.latitude, telemetry.longitude),
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ETA Floating Card on top of Map
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ESTIMATED ARRIVAL', style: AppTextStyles.caption),
                                  const SizedBox(height: 2),
                                  Text(
                                    etaFormatted,
                                    style: AppTextStyles.metricValue.copyWith(
                                      color: AppColors.emergencyRed,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 36,
                                width: 1,
                                color: theme.dividerColor,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('VEHICLE SPEED', style: AppTextStyles.caption),
                                  const SizedBox(height: 2),
                                  Text(
                                    speed,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Vehicle & Telemetry Details Panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ambulanceId,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                telemetry?.vehicleNumber ?? 'TN-01-EM-1081',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('LAST TELEMETRY UPDATE', style: AppTextStyles.caption),
                              Text(
                                DateFormatter.formatTime(telemetry?.timestamp ?? DateTime.now()),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Calling Driver: ${telemetry?.driverPhone ?? "+91 98401 23456"}'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.call_rounded, size: 18),
                              label: const Text('CALL DRIVER'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('STATUS VIEW'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
