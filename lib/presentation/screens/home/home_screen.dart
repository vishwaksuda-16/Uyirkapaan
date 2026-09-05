import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/emergency_request.dart';
import '../../../domain/entities/emergency_type.dart';
import '../../../domain/entities/location_data.dart';
import '../../../domain/entities/nearby_poi.dart';
import '../../../domain/entities/request_status.dart';
import '../../../domain/entities/tracking_info.dart';
import '../../../domain/repositories/tracking_repository.dart';
import '../../../routing/route_paths.dart';
import '../../controllers/emergency_controller.dart';
import '../../controllers/location_controller.dart';
import '../../controllers/simulation_controller.dart';
import '../../widgets/counter_stepper.dart';
import '../../widgets/emergency_button.dart';
import '../../widgets/map/map_style_selector.dart';
import '../../widgets/map/openfreemap_view.dart';
import '../../widgets/status_badge.dart';
import '../../../core/utils/map_route_geometry.dart';
import '../../../main.dart';

/// Unified Main Screen for UyirKappan Module 1 (Bystander App).
/// The MapLibre map IS the main screen background, featuring interactive pinpointing,
/// one-tap emergency dispatch, and real-time ambulance tracking right on this screen.
class HomeScreen extends StatefulWidget {
  final EmergencyController emergencyController;
  final LocationController locationController;
  final SimulationController simulationController;
  final TrackingRepository? trackingRepository;

  const HomeScreen({
    super.key,
    required this.emergencyController,
    required this.locationController,
    required this.simulationController,
    this.trackingRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OpenFreeMapStyle _selectedMapStyle = OpenFreeMapStyle.bright;
  TrackingInfo? _currentTelemetry;
  StreamSubscription<TrackingInfo>? _trackingSubscription;
  String? _lastSubscribedRequestId;
  bool _showHospitals = true;
  bool _showAmbulances = true;
  bool _isAdjustingLocation = false;
  int _recenterCounter = 0;

  @override
  void initState() {
    super.initState();
    _checkAndSubscribeTracking();
    widget.emergencyController.addListener(_onEmergencyStateChanged);
    widget.locationController.addListener(_onLocationChanged);
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndSubscribeTracking();
  }

  @override
  void dispose() {
    widget.emergencyController.removeListener(_onEmergencyStateChanged);
    widget.locationController.removeListener(_onLocationChanged);
    _trackingSubscription?.cancel();
    super.dispose();
  }

  void _onEmergencyStateChanged() {
    _checkAndSubscribeTracking();
    if (mounted) setState(() {});
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  void _checkAndSubscribeTracking() {
    final activeRequest = widget.emergencyController.activeRequest;
    if (activeRequest != null && activeRequest.status.isActive && widget.trackingRepository != null) {
      if (_lastSubscribedRequestId != activeRequest.requestId) {
        _lastSubscribedRequestId = activeRequest.requestId;
        _trackingSubscription?.cancel();

        widget.trackingRepository!.getTrackingInfo(activeRequest.requestId).then((info) {
          if (mounted && info != null) {
            setState(() => _currentTelemetry = info);
          }
        });

        _trackingSubscription = widget.trackingRepository!
            .watchTrackingUpdates(activeRequest.requestId)
            .listen((telemetry) {
          if (mounted) {
            setState(() => _currentTelemetry = telemetry);
          }
        });
      }
    } else {
      if (_lastSubscribedRequestId != null) {
        _lastSubscribedRequestId = null;
        _trackingSubscription?.cancel();
        _trackingSubscription = null;
      }
    }
  }

  void _dispatchAmbulance() async {
    final loc = widget.locationController.emergencyLocation ??
        LocationData(
          latitude: MapConstants.defaultLatitude,
          longitude: MapConstants.defaultLongitude,
          timestamp: DateTime.now(),
        );

    widget.emergencyController.markT0Timestamp();
    widget.emergencyController.setAdditionalNotes('Dispatched directly from main screen map');

    await widget.emergencyController.submitEmergencyRequest(
      emergencyLocation: loc,
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Emergency Request?'),
        content: const Text(
          'Are you sure you want to cancel this ambulance dispatch? This action will recall the assigned emergency unit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('KEEP REQUEST ACTIVE'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.emergencyController.cancelActiveRequest(reason: 'Cancelled by user');
              setState(() => _currentTelemetry = null);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            child: const Text('CANCEL EMERGENCY'),
          ),
        ],
      ),
    );
  }

  void _toggleThemeMode() {
    final current = appThemeModeNotifier.value;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    appThemeModeNotifier.value = next;
    setState(() {
      _selectedMapStyle = next == ThemeMode.dark ? OpenFreeMapStyle.dark : OpenFreeMapStyle.bright;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          next == ThemeMode.dark ? '🌙 Night mode enabled (Dark map & UI)' : '☀️ Day mode enabled (Bright map & UI)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildThemeToggleButton({required bool isDesktop}) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return Tooltip(
          message: isDark ? 'Switch to Day Mode (Light)' : 'Switch to Night Mode (Dark)',
          child: InkWell(
            onTap: _toggleThemeMode,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 10, vertical: isDesktop ? 8 : 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                    size: isDesktop ? 18 : 16,
                    color: isDark ? Colors.amberAccent : Colors.orangeAccent.shade700,
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 6),
                    Text(
                      isDark ? 'Night' : 'Day',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Computes simulated street navigation waypoints for realistic Google Maps route rendering.
  List<LocationData>? _calculateActiveRoute({
    required EmergencyRequest? activeRequest,
    required bool isAmbulanceAssigned,
    required bool isNoAmbulanceAvailable,
    required LocationData? incidentLocation,
    required LocationData? ambulanceLocation,
    required NearbyHospital? assignedHospital,
  }) {
    if (incidentLocation == null || assignedHospital == null) return null;

    final hospLoc = LocationData(
      latitude: assignedHospital.latitude,
      longitude: assignedHospital.longitude,
      timestamp: DateTime.now(),
    );

    if (isNoAmbulanceAvailable) {
      // Scenario 4: Fast corridor to nearest trauma hospital for emergency self-transport
      return MapRouteGeometry.buildSimulatedRoute(
        from: incidentLocation,
        to: hospLoc,
      );
    }

    if (!isAmbulanceAssigned || ambulanceLocation == null || activeRequest == null) {
      return null;
    }

    final status = activeRequest.status;

    if (status == RequestStatus.patientOnboard ||
        status == RequestStatus.enRouteToHospital ||
        status == RequestStatus.arrivedAtHospital) {
      // Hospital leg: Ambulance actively navigating to emergency hospital
      return MapRouteGeometry.buildSimulatedRoute(
        from: ambulanceLocation,
        to: hospLoc,
      );
    }

    // Pickup & Drop: Ambulance -> Incident (Pickup) -> Hospital (Drop)
    final pickupLeg = MapRouteGeometry.buildSimulatedRoute(
      from: ambulanceLocation,
      to: incidentLocation,
    );
    final dropLeg = MapRouteGeometry.buildSimulatedRoute(
      from: incidentLocation,
      to: hospLoc,
    );

    return [
      ...pickupLeg,
      ...dropLeg.skip(1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final EmergencyRequest? activeRequest = widget.emergencyController.activeRequest;
    final bool isNoAmbulanceAvailable = activeRequest != null && activeRequest.status == RequestStatus.noAmbulanceAvailable;
    final bool hasActiveRequest = (activeRequest != null && activeRequest.status.isActive) || isNoAmbulanceAvailable;
    final bool isAmbulanceAssigned = activeRequest != null &&
        activeRequest.status.isActive &&
        activeRequest.assignedAmbulanceId != null &&
        activeRequest.status != RequestStatus.searching &&
        activeRequest.status != RequestStatus.created;

    // Determine target location for pinpoint / tracking
    final LocationData? incidentLocation = activeRequest?.emergencyLocation ?? widget.locationController.emergencyLocation;
    final LocationData? ambulanceLocation = (hasActiveRequest && !isNoAmbulanceAvailable && _currentTelemetry != null)
        ? LocationData(
            latitude: _currentTelemetry!.latitude,
            longitude: _currentTelemetry!.longitude,
            timestamp: _currentTelemetry!.timestamp,
          )
        : null;

    final String ambulanceId = _currentTelemetry?.ambulanceId ?? activeRequest?.assignedAmbulanceId ?? 'AMB-CH-042';

    // Emergency Network POIs: Hospitals & Standby Ambulances around current location
    final double centerLat = incidentLocation?.latitude ?? MapConstants.defaultLatitude;
    final double centerLng = incidentLocation?.longitude ?? MapConstants.defaultLongitude;
    final hospitals = NearbyEmergencyService.getHospitalsAround(centerLat, centerLng);
    final standbyAmbulances = NearbyEmergencyService.getStandbyAmbulancesAround(centerLat, centerLng);

    // Identify assigned hospital (or nearest casualty hospital for self-transport)
    NearbyHospital? assignedHospital;
    if (activeRequest?.hospitalDestination != null && hospitals.isNotEmpty) {
      final destLower = activeRequest!.hospitalDestination!.toLowerCase();
      assignedHospital = hospitals.cast<NearbyHospital?>().firstWhere(
        (h) => h!.name.toLowerCase().contains(destLower) || destLower.contains(h.name.toLowerCase()),
        orElse: () => null,
      );
    }
    assignedHospital ??= hospitals.isNotEmpty ? hospitals.first : null;

    // Visibility filtering:
    // When ambulance is assigned: hide all other standby ambulances & other hospitals. Focus strictly on assigned unit and hospital.
    // When no ambulance is available: show only the nearest hospital for self-transport.
    final List<NearbyAmbulance> visibleAmbulances = (isAmbulanceAssigned || isNoAmbulanceAvailable)
        ? const <NearbyAmbulance>[]
        : (_showAmbulances ? standbyAmbulances : const <NearbyAmbulance>[]);

    final List<NearbyHospital> visibleHospitals = (isAmbulanceAssigned || isNoAmbulanceAvailable)
        ? (assignedHospital != null ? [assignedHospital] : const <NearbyHospital>[])
        : (_showHospitals ? hospitals : const <NearbyHospital>[]);

    // Google Maps blue navigation polyline waypoints
    final List<LocationData>? activeRouteWaypoints = _calculateActiveRoute(
      activeRequest: activeRequest,
      isAmbulanceAssigned: isAmbulanceAssigned,
      isNoAmbulanceAvailable: isNoAmbulanceAvailable,
      incidentLocation: incidentLocation,
      ambulanceLocation: ambulanceLocation,
      assignedHospital: assignedHospital,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. FULL-SCREEN BACKGROUND: OpenFreeMap MapLibre GL JS Vector Map
          Positioned.fill(
            child: OpenFreeMapView(
              incidentLocation: incidentLocation ??
                  LocationData(
                    latitude: MapConstants.defaultLatitude,
                    longitude: MapConstants.defaultLongitude,
                    timestamp: DateTime.now(),
                  ),
              ambulanceLocation: ambulanceLocation,
              heading: _currentTelemetry?.headingDegrees,
              ambulanceId: ambulanceId,
              routeWaypoints: activeRouteWaypoints,
              style: _selectedMapStyle,
              isPickerMode: _isAdjustingLocation && !hasActiveRequest,
              showSearchRadar: activeRequest != null && activeRequest.status == RequestStatus.searching,
              recenterTrigger: _recenterCounter,
              nearbyHospitals: visibleHospitals,
              nearbyAmbulances: visibleAmbulances,
              onLocationPicked: (newLoc) {
                if (_isAdjustingLocation && !hasActiveRequest) {
                  widget.locationController.setManualEmergencyLocation(
                    latitude: newLoc.latitude,
                    longitude: newLoc.longitude,
                    address: 'Pickup Pin (${newLoc.latitude.toStringAsFixed(4)}, ${newLoc.longitude.toStringAsFixed(4)})',
                  );
                }
              },
            ),
          ),

          // 1B. PINPOINT ADJUSTMENT ACTIVE BANNER
          if (_isAdjustingLocation && !hasActiveRequest)
            Positioned(
              top: isDesktop ? 76 : 155,
              left: 14,
              right: 14,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 760 : 540),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 16, vertical: isDesktop ? 12 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.emergencyRed, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: Colors.amber, size: isDesktop ? 28 : 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tap map or drag pin to fine-tune pickup spot',
                            style: TextStyle(color: Colors.white, fontSize: isDesktop ? 13.5 : 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            setState(() => _isAdjustingLocation = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🔒 Incident location locked.')),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emergencyRed,
                            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 18 : 14, vertical: isDesktop ? 10 : 8),
                            minimumSize: Size(isDesktop ? 88 : 76, isDesktop ? 42 : 38),
                          ),
                          child: Text('LOCK PIN', style: TextStyle(fontSize: isDesktop ? 13 : 12, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 2. TOP FLOATING APP BAR (Widescreen Single-Row Navbar on Desktop)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1440 : 540),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 14, vertical: isDesktop ? 10 : 8),
                    child: isDesktop
                        ? _buildDesktopTopNavBar(
                            context: context,
                            isDark: isDark,
                            hospitals: hospitals,
                            standbyAmbulances: standbyAmbulances,
                            isAmbulanceAssigned: isAmbulanceAssigned,
                            assignedAmbulanceId: ambulanceId,
                            assignedHospital: assignedHospital,
                          )
                        : _buildMobileTopBar(
                            context: context,
                            isDark: isDark,
                            hospitals: hospitals,
                            standbyAmbulances: standbyAmbulances,
                            isAmbulanceAssigned: isAmbulanceAssigned,
                            assignedAmbulanceId: ambulanceId,
                            assignedHospital: assignedHospital,
                          ),
                  ),
                ),
              ),
            ),
          ),

          // 3. RIGHT FLOATING ACTIONS (GPS Re-center & Emergency Call)
          Positioned(
            right: isDesktop ? 24 : 16,
            bottom: isDesktop ? 135 : (hasActiveRequest ? 280 : 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: isDesktop ? 54 : 56,
                  height: isDesktop ? 54 : 56,
                  child: FloatingActionButton(
                    heroTag: 'home_recenter_gps',
                    onPressed: () async {
                      await widget.locationController.snapToCurrentGps();
                      setState(() {
                        _isAdjustingLocation = false;
                        _recenterCounter++;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📍 Centered on your current GPS position')),
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.emergencyDarkRed,
                    elevation: 6,
                    tooltip: 'Snap to GPS Position',
                    child: Icon(Icons.my_location_rounded, size: isDesktop ? 26 : 26),
                  ),
                ),
                SizedBox(height: isDesktop ? 12 : 12),
                SizedBox(
                  width: isDesktop ? 54 : 56,
                  height: isDesktop ? 54 : 56,
                  child: FloatingActionButton(
                    heroTag: 'home_dial_108',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling Direct Helpline: 108...')),
                      );
                    },
                    backgroundColor: AppColors.emergencyRed,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    tooltip: 'Call 108 Helpline',
                    child: Icon(Icons.phone_in_talk_rounded, size: isDesktop ? 26 : 24),
                  ),
                ),
              ],
            ),
          ),

          // 4. BOTTOM FLOATING EMERGENCY PANEL / LIVE TRACKING SHEET
          // Desktop uses a full-width command cockpit dock; Mobile uses a clean stacked sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: isDesktop ? 16 : 14,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1440 : 540),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 14),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isNoAmbulanceAvailable
                          ? (isDesktop
                              ? _buildDesktopNoAmbulanceDock(context, activeRequest, assignedHospital, theme, isDark)
                              : _buildNoAmbulanceSheet(context, activeRequest, assignedHospital, theme, isDark))
                          : (hasActiveRequest
                              ? (isDesktop
                                  ? _buildDesktopActiveTrackingDock(context, activeRequest, assignedHospital, theme, isDark)
                                  : _buildActiveTrackingSheet(context, activeRequest, assignedHospital, theme, isDark, false))
                              : (isDesktop
                                  ? _buildDesktopIdleEmergencyDock(context, theme, isDark)
                                  : _buildIdleEmergencySheet(context, theme, isDark, false))),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop Top Navigation Bar (Single Row, Widescreen)
  Widget _buildDesktopTopNavBar({
    required BuildContext context,
    required bool isDark,
    required List<NearbyHospital> hospitals,
    required List<NearbyAmbulance> standbyAmbulances,
    bool isAmbulanceAssigned = false,
    String? assignedAmbulanceId,
    NearbyHospital? assignedHospital,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Branding Icon & Title
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.emergencyRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.emergencyRed,
                ),
              ),
              Text(
                'Emergency Response System',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),
          Container(width: 1, height: 28, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(width: 12),

          // Middle Scrollable Section (Style Selector + POI chips)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MapStyleSelector(
                    currentStyle: _selectedMapStyle,
                    isEmbedded: true,
                    onStyleSelected: (style) {
                      setState(() => _selectedMapStyle = style);
                    },
                  ),
                  const SizedBox(width: 10),
                  if (isAmbulanceAssigned) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF16A34A), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🚑', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            'Unit in Focus: ${assignedAmbulanceId ?? "Assigned"}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏥', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              assignedHospital?.name ?? 'Assigned Hospital',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildPoiFilterChip(
                      label: '🏥 Hospitals (${hospitals.length})',
                      isSelected: _showHospitals,
                      color: const Color(0xFF0284C7),
                      isDesktop: true,
                      onTap: () => setState(() => _showHospitals = !_showHospitals),
                    ),
                    const SizedBox(width: 8),
                    _buildPoiFilterChip(
                      label: '🚑 Ambulances (${standbyAmbulances.length})',
                      isSelected: _showAmbulances,
                      color: const Color(0xFF16A34A),
                      isDesktop: true,
                      onTap: () => setState(() => _showAmbulances = !_showAmbulances),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Night / Dark Mode Toggle
          _buildThemeToggleButton(isDesktop: true),

          const SizedBox(width: 10),

          // DEMO Quick Pill
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, RoutePaths.simulationScenarios);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade700, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DEMO',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.tune_rounded, size: 15, color: Colors.amber.shade900),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile Top Bar (Clean, Compact Column Layout)
  Widget _buildMobileTopBar({
    required BuildContext context,
    required bool isDark,
    required List<NearbyHospital> hospitals,
    required List<NearbyAmbulance> standbyAmbulances,
    bool isAmbulanceAssigned = false,
    String? assignedAmbulanceId,
    NearbyHospital? assignedHospital,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand Capsule + Simulation Switcher + Theme Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                  Text(
                    'Emergency Response System',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildThemeToggleButton(isDesktop: false),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, RoutePaths.simulationScenarios);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade700, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'DEMO',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Floating Map Style Selector Pill
        MapStyleSelector(
          currentStyle: _selectedMapStyle,
          onStyleSelected: (style) {
            setState(() => _selectedMapStyle = style);
          },
        ),

        // POI Toggle Row (Hospitals & Ambulances)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: isAmbulanceAssigned
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF16A34A), width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🚑', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            'Unit: ${assignedAmbulanceId ?? "Assigned"}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0284C7), width: 1.1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏥', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              assignedHospital?.name ?? 'Assigned Hospital',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPoiFilterChip(
                      label: '🏥 Hospitals (${hospitals.length})',
                      isSelected: _showHospitals,
                      color: const Color(0xFF0284C7),
                      isDesktop: false,
                      onTap: () => setState(() => _showHospitals = !_showHospitals),
                    ),
                    const SizedBox(width: 8),
                    _buildPoiFilterChip(
                      label: '🚑 Ambulances (${standbyAmbulances.length})',
                      isSelected: _showAmbulances,
                      color: const Color(0xFF16A34A),
                      isDesktop: false,
                      onTap: () => setState(() => _showAmbulances = !_showAmbulances),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Desktop Widescreen Command Cockpit Dock for Idle State
  Widget _buildDesktopIdleEmergencyDock(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final loc = widget.locationController.emergencyLocation;
    final selectedType = widget.emergencyController.selectedType;

    return Container(
      key: const ValueKey('desktop_idle_emergency_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section 1: Location & Direct Helpline (Width: 380)
          SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Emergency Medical Assistance',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Direct Emergency Helpline: 108 / 112')),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyLightRed,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_rounded, size: 13, color: AppColors.emergencyDarkRed),
                            SizedBox(width: 4),
                            Text(
                              'Direct Emergency Helpline',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emergencyDarkRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Compact Location Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isAdjustingLocation ? AppColors.emergencyRed : const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      width: _isAdjustingLocation ? 1.8 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isAdjustingLocation ? Icons.edit_location_alt_rounded : Icons.location_on_rounded,
                          color: AppColors.emergencyRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _isAdjustingLocation ? Colors.amber : const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isAdjustingLocation ? 'ADJUSTING PIN' : 'LOCATION LOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: _isAdjustingLocation
                                        ? Colors.amber.shade700
                                        : (isDark ? Colors.blue.shade300 : const Color(0xFF1D4ED8)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc?.address ??
                                  (loc != null
                                      ? '${loc.latitude.toStringAsFixed(4)}° N, ${loc.longitude.toStringAsFixed(4)}° E'
                                      : '13.0827° N, 80.2707° E (Chennai Central Corridor)'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() => _isAdjustingLocation = !_isAdjustingLocation);
                          if (!_isAdjustingLocation) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🔒 Incident location locked.')),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _isAdjustingLocation
                              ? AppColors.emergencyRed
                              : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFDBEAFE)),
                          foregroundColor: _isAdjustingLocation
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF1E40AF)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(78, 34),
                        ),
                        child: Text(
                          _isAdjustingLocation ? 'LOCK PIN' : 'ADJUST PIN',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 1,
              height: 75,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          // Section 2: Categories + Victims (Expanded)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Select Emergency Scenario:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.personal_injury_rounded, size: 18, color: AppColors.emergencyRed),
                        const SizedBox(width: 4),
                        const Text(
                          'Victims:',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        CounterStepper(
                          count: widget.emergencyController.victimCount,
                          min: AppConstants.minVictims,
                          max: AppConstants.maxVictims,
                          isCompact: true,
                          onIncrement: widget.emergencyController.incrementVictimCount,
                          onDecrement: widget.emergencyController.decrementVictimCount,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: EmergencyType.values.length,
                    itemBuilder: (context, index) {
                      final type = EmergencyType.values[index];
                      final isSelected = type == selectedType;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => widget.emergencyController.setEmergencyType(type),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.emergencyRed
                                  : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? AppColors.emergencyRed : Colors.black.withValues(alpha: 0.12),
                                width: 1.3,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type.icon,
                                  size: 18,
                                  color: isSelected ? Colors.white : AppColors.emergencyRed,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  type.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 1,
              height: 75,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          // Section 3: Request Ambulance Button (Width: 240)
          SizedBox(
            width: 240,
            child: EmergencyButton(
              label: 'REQUEST AMBULANCE',
              subLabel: 'TAP FOR IMMEDIATE LIVE DISPATCH',
              isLoading: widget.emergencyController.submissionState == SubmissionState.submitting,
              onPressed: _dispatchAmbulance,
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop Widescreen Command Cockpit Dock for Active Tracking State
  Widget _buildDesktopActiveTrackingDock(
    BuildContext context,
    EmergencyRequest request,
    NearbyHospital? assignedHospital,
    ThemeData theme,
    bool isDark,
  ) {
    final status = request.status;
    final isFallbackActive = request.fallbackCount > 0 && status == RequestStatus.searching;
    final etaFormatted = _currentTelemetry?.eta?.formattedEta ?? '6 min';
    final speed = _currentTelemetry?.speedKmH != null ? '${_currentTelemetry!.speedKmH!.toStringAsFixed(0)} km/h' : '48 km/h';
    final ambulanceId = _currentTelemetry?.ambulanceId ?? request.assignedAmbulanceId ?? 'AMB-CH-042';

    return Container(
      key: const ValueKey('desktop_active_tracking_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Section 1: ETA & Status Badge
          SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            'ETA: ${etaFormatted.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: status),
                  ],
                ),
                if (isFallbackActive) ...[
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.sync_problem_rounded, color: AppColors.statusFallback, size: 14),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Cascading fallback: Re-routing to next unit',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.statusFallback),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Vertical Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 1,
              height: 65,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          // Section 2: Vehicle & Driver details + Destination Hospital + Live Telemetry
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.emergencyLightRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Center(
                    child: Text('🚑', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ambulanceId,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    ),
                    Text(
                      'Driver: ${request.assignedDriverName ?? "Suresh Kumar"} • Unit in Focus',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling Driver: 108...')),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('CALL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Destination Hospital Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_hospital_rounded, size: 14, color: Color(0xFF0284C7)),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          assignedHospital?.name ?? request.hospitalDestination ?? 'General Hospital',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildTelemetryBadge(Icons.speed_rounded, 'SPEED', speed, AppColors.info),
                const SizedBox(width: 20),
                _buildTelemetryBadge(Icons.alt_route_rounded, 'DISTANCE', '2.4 km', AppColors.emergencyRed),
                const SizedBox(width: 20),
                _buildTelemetryBadge(Icons.traffic_rounded, 'CORRIDOR', 'ACTIVE', AppColors.success),
              ],
            ),
          ),

          // Vertical Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 1,
              height: 65,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          // Section 3: Cancel Emergency Button
          SizedBox(
            width: 140,
            child: FilledButton(
              onPressed: _showCancelDialog,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emergencyRed.withValues(alpha: 0.15),
                foregroundColor: AppColors.emergencyRed,
                elevation: 0,
                side: const BorderSide(color: AppColors.emergencyRed, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Active Tracking Sheet: Renders live ETA, vehicle badge, driver profile, speed, and status timeline (Mobile)
  Widget _buildActiveTrackingSheet(
    BuildContext context,
    EmergencyRequest request,
    NearbyHospital? assignedHospital,
    ThemeData theme,
    bool isDark, [
    bool isDesktop = false,
  ]) {
    final status = request.status;
    final isFallbackActive = request.fallbackCount > 0 && status == RequestStatus.searching;
    final etaFormatted = _currentTelemetry?.eta?.formattedEta ?? '6 min';
    final speed = _currentTelemetry?.speedKmH != null ? '${_currentTelemetry!.speedKmH!.toStringAsFixed(0)} km/h' : '48 km/h';
    final ambulanceId = _currentTelemetry?.ambulanceId ?? request.assignedAmbulanceId ?? 'AMB-CH-042';

    return Container(
      key: const ValueKey('active_tracking_sheet'),
      padding: EdgeInsets.all(isDesktop ? 22 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cascading Fallback Alert Banner
          if (isFallbackActive) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.statusFallback.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.statusFallback, width: 1.2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync_problem_rounded, color: AppColors.statusFallback, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Re-routing: Driver could not proceed. Cascading fallback dispatching next nearest unit.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.statusFallback),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ETA & Status Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 10, vertical: isDesktop ? 6 : 5),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_rounded, color: Colors.white, size: isDesktop ? 16 : 14),
                        const SizedBox(width: 5),
                        Text(
                          'ETA: ${etaFormatted.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 13.5 : 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: status),
                ],
              ),
              TextButton(
                onPressed: _showCancelDialog,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: isDesktop ? 12 : 11)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Vehicle & Driver Details
          Row(
            children: [
              Container(
                width: isDesktop ? 52 : 44,
                height: isDesktop ? 52 : 44,
                decoration: BoxDecoration(
                  color: AppColors.emergencyLightRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text('🚑', style: TextStyle(fontSize: isDesktop ? 26 : 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ambulanceId,
                      style: TextStyle(fontSize: isDesktop ? 17.5 : 16, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    ),
                    Text(
                      'Driver: ${request.assignedDriverName ?? "Suresh Kumar"} • Unit in Focus',
                      style: TextStyle(fontSize: isDesktop ? 13 : 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling Driver: 108...')),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 12, vertical: isDesktop ? 9 : 8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: isDesktop ? 16 : 14),
                      const SizedBox(width: 4),
                      Text('CALL', style: TextStyle(color: Colors.white, fontSize: isDesktop ? 12 : 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Destination Hospital Card (Mobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'DESTINATION HOSPITAL',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0284C7), letterSpacing: 0.4),
                      ),
                      Text(
                        assignedHospital?.name ?? request.hospitalDestination ?? 'Rajiv Gandhi Govt General Hospital',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ICU READY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Telemetry Row (Live speed, distance, corridor)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTelemetryBadge(Icons.speed_rounded, 'SPEED', speed, AppColors.info),
              Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
              _buildTelemetryBadge(Icons.alt_route_rounded, 'DISTANCE', '2.4 km', AppColors.emergencyRed),
              Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
              _buildTelemetryBadge(Icons.traffic_rounded, 'CORRIDOR', 'ACTIVE', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  /// Desktop Widescreen Command Cockpit Dock for Scenario 4 (No Ambulance Available)
  Widget _buildDesktopNoAmbulanceDock(
    BuildContext context,
    EmergencyRequest request,
    NearbyHospital? nearestHospital,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      key: const ValueKey('desktop_no_ambulance_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.emergencyRed,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Section 1: Alert Header + Explanation + Dismiss
          SizedBox(
            width: 330,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 5),
                          Text(
                            'NO AMBULANCES AVAILABLE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'All 40 network emergency units are currently deployed on active critical calls.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    widget.emergencyController.resetForm();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(120, 32),
                  ),
                  child: const Text('DISMISS / RETRY SEARCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 1,
              height: 75,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          // Section 2: Nearest Casualty Emergency Center for Self-Transport
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF2563EB), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('RECOMMENDED SELF-TRANSPORT', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${nearestHospital?.distanceKm.toStringAsFixed(1) ?? '1.8'} km away',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nearestHospital?.name ?? 'Rajiv Gandhi Govt General Hospital (Casualty & Trauma)',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${nearestHospital?.emergencyBeds ?? 45} Casualty beds ready • Blue self-transport route highlighted on map',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vertical Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 1,
              height: 75,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          // Section 3: Call 108 / 112 Direct Helpline Button
          SizedBox(
            width: 220,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    duration: Duration(seconds: 4),
                    content: Text('📞 Connecting to 108 / 112 State Emergency Control Room...'),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_forwarded_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('CALL 108 NOW', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text('DIRECT DISPATCH HOTLINE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile Emergency Sheet for Scenario 4 (No Ambulance Available)
  Widget _buildNoAmbulanceSheet(
    BuildContext context,
    EmergencyRequest request,
    NearbyHospital? nearestHospital,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      key: const ValueKey('mobile_no_ambulance_sheet'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.emergencyRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Tag Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'NO AMBULANCE AVAILABLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => widget.emergencyController.resetForm(),
                child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'All 40 network emergency ambulances in Chennai are currently engaged. Please call emergency services immediately or head to the nearest casualty center.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Direct Call Helpline Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    duration: Duration(seconds: 4),
                    content: Text('📞 Connecting to 108 Emergency Control Room...'),
                  ),
                );
              },
              icon: const Icon(Icons.phone_forwarded_rounded, size: 20),
              label: const Text('CALL 108 DIRECT HELPLINE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Nearest Hospital Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('NEAREST CASUALTY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                          const SizedBox(width: 6),
                          Text(
                            '${nearestHospital?.distanceKm.toStringAsFixed(1) ?? '1.8'} km',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nearestHospital?.name ?? 'Rajiv Gandhi Govt General Hospital',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Blue route highlighted on map for self-transport',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Idle Emergency Sheet: Category selectors, victim stepper, and dominant SOS trigger button
  Widget _buildIdleEmergencySheet(
    BuildContext context,
    ThemeData theme,
    bool isDark, [
    bool isDesktop = false,
  ]) {
    final loc = widget.locationController.emergencyLocation;
    final selectedType = widget.emergencyController.selectedType;

    return Container(
      key: const ValueKey('idle_emergency_sheet'),
      padding: EdgeInsets.all(isDesktop ? 22 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Emergency Medical Assistance',
                  style: TextStyle(
                    fontSize: isDesktop ? 19 : 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Direct Emergency Helpline: 108 / 112')),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 10, vertical: isDesktop ? 7 : 6),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyLightRed,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_rounded, size: isDesktop ? 16 : 14, color: AppColors.emergencyDarkRed),
                      const SizedBox(width: 4),
                      Text(
                        'Direct Emergency Helpline',
                        style: TextStyle(
                          fontSize: isDesktop ? 12 : 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emergencyDarkRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // High-Visibility Dedicated Current Incident Location Card (Opaque against Map Bleed)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 16 : 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isAdjustingLocation ? AppColors.emergencyRed : const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  width: _isAdjustingLocation ? 2.0 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 12 : 10),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAdjustingLocation ? Icons.edit_location_alt_rounded : Icons.location_on_rounded,
                      color: AppColors.emergencyRed,
                      size: isDesktop ? 28 : 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isAdjustingLocation ? Colors.amber : const Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isAdjustingLocation ? 'ADJUSTING PIN' : 'LOCATION LOCKED',
                                style: TextStyle(
                                  fontSize: isDesktop ? 11.5 : 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: _isAdjustingLocation
                                      ? Colors.amber.shade700
                                      : (isDark ? Colors.blue.shade300 : const Color(0xFF1D4ED8)),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc?.address ??
                              (loc != null
                                  ? '${loc.latitude.toStringAsFixed(4)}° N, ${loc.longitude.toStringAsFixed(4)}° E'
                                  : '13.0827° N, 80.2707° E (Chennai Central Corridor)'),
                          style: TextStyle(
                            fontSize: isDesktop ? 15.5 : 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isAdjustingLocation
                              ? 'Tap map to position marker or drag pin'
                              : 'Position locked • Tap [Adjust Pin] to modify',
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Adjust Pin / Lock Pin Toggle Button
                  FilledButton.tonal(
                    onPressed: () {
                      setState(() => _isAdjustingLocation = !_isAdjustingLocation);
                      if (!_isAdjustingLocation) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔒 Incident location locked.')),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _isAdjustingLocation
                          ? AppColors.emergencyRed
                          : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFDBEAFE)),
                      foregroundColor: _isAdjustingLocation
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1E40AF)),
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10, vertical: isDesktop ? 10 : 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size(isDesktop ? 96 : 82, isDesktop ? 44 : 40),
                    ),
                    child: Text(
                      _isAdjustingLocation ? 'LOCK PIN' : 'ADJUST PIN',
                      style: TextStyle(fontSize: isDesktop ? 12.5 : 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Emergency Category Selection Pills (Horizontal Scroll - Enlarged)
          SizedBox(
            height: isDesktop ? 56 : 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: EmergencyType.values.length,
              itemBuilder: (context, index) {
                final type = EmergencyType.values[index];
                final isSelected = type == selectedType;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => widget.emergencyController.setEmergencyType(type),
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 18 : 16,
                        vertical: isDesktop ? 12 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.emergencyRed
                            : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? AppColors.emergencyRed : Colors.black.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: isDesktop ? 24 : 20,
                            color: isSelected ? Colors.white : AppColors.emergencyRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: isDesktop ? 15 : 14,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Victims Stepper Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.personal_injury_rounded,
                      size: isDesktop ? 24 : 20,
                      color: AppColors.emergencyRed,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Patients / Victims:',
                        style: TextStyle(
                          fontSize: isDesktop ? 15 : 13,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CounterStepper(
                count: widget.emergencyController.victimCount,
                min: AppConstants.minVictims,
                max: AppConstants.maxVictims,
                isCompact: !isDesktop,
                onIncrement: widget.emergencyController.incrementVictimCount,
                onDecrement: widget.emergencyController.decrementVictimCount,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Primary Dominant SOS Emergency Trigger Button
          EmergencyButton(
            label: 'REQUEST AMBULANCE',
            subLabel: 'TAP FOR IMMEDIATE LIVE DISPATCH',
            isLoading: widget.emergencyController.submissionState == SubmissionState.submitting,
            onPressed: _dispatchAmbulance,
          ),
        ],
      ),
    );
  }

  Widget _buildPoiFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    bool isDesktop = false,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 18 : 14,
          vertical: isDesktop ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 13.5 : 12.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryBadge(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}
