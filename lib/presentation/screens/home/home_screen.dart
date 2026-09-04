import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../routing/route_paths.dart';
import '../../controllers/emergency_controller.dart';
import '../../controllers/location_controller.dart';
import '../../controllers/simulation_controller.dart';
import '../../widgets/emergency_button.dart';
import '../../widgets/emergency_call_card.dart';
import '../../widgets/location_card.dart';
import '../../widgets/simulation_banner.dart';

/// Screen 1: Clean, emergency-focused Home Screen.
/// Designed for fast single-action trigger under high pressure.
class HomeScreen extends StatelessWidget {
  final EmergencyController emergencyController;
  final LocationController locationController;
  final SimulationController simulationController;

  const HomeScreen({
    super.key,
    required this.emergencyController,
    required this.locationController,
    required this.simulationController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Development / Simulation Banner
          ListenableBuilder(
            listenable: simulationController,
            builder: (context, _) {
              return SimulationBanner(
                simulationController: simulationController,
                onOpenScenarios: () {
                  Navigator.pushNamed(context, RoutePaths.simulationScenarios);
                },
              );
            },
          ),

          // Active Emergency Recovery Banner (if an incident is in progress)
          ListenableBuilder(
            listenable: emergencyController,
            builder: (context, _) {
              if (emergencyController.hasActiveRequest) {
                return Container(
                  width: double.infinity,
                  color: AppColors.statusAssigned,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ACTIVE EMERGENCY IN PROGRESS (${emergencyController.activeRequest!.requestId})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, RoutePaths.requestStatus);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white24,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: const Text('VIEW STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Main Scrollable Emergency Content
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Branding & Tagline
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyLightRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.health_and_safety_rounded,
                            color: AppColors.emergencyRed,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: AppColors.emergencyRed,
                              ),
                            ),
                            Text(
                              AppConstants.appTagline,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Large Emergency Assistance Heading
                    const Text(
                      'Emergency Medical Assistance',
                      style: AppTextStyles.heroHeadline,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap below to request immediate ambulance dispatch to your location.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Primary Dominant Emergency Button
                    EmergencyButton(
                      onPressed: () {
                        // Mark T0 client timestamp
                        emergencyController.markT0Timestamp();
                        // Proceed to emergency flow (Step 1: Emergency Details or Location Confirm)
                        Navigator.pushNamed(context, RoutePaths.emergencyDetails);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Current Location Card with GPS status
                    ListenableBuilder(
                      listenable: locationController,
                      builder: (context, _) {
                        return LocationCard(
                          locationController: locationController,
                          onAdjustLocation: () {
                            Navigator.pushNamed(context, RoutePaths.locationPicker);
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Emergency Phone Backup
                    const EmergencyCallCard(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
