import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/map_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/location_data.dart';
import '../../../domain/entities/nearby_poi.dart';

/// Native Mobile & Desktop implementation of OpenFreeMap powered by flutter_map.
class PlatformOpenFreeMapView extends StatefulWidget {
  final LocationData? userLocation;
  final LocationData? incidentLocation;
  final LocationData? ambulanceLocation;
  final double? heading;
  final String? ambulanceId;
  final List<LocationData>? routeWaypoints;
  final List<NearbyHospital>? nearbyHospitals;
  final List<NearbyAmbulance>? nearbyAmbulances;
  final OpenFreeMapStyle style;
  final bool isPickerMode;
  final bool showSearchRadar;
  final int recenterTrigger;
  final ValueChanged<LocationData>? onLocationPicked;

  const PlatformOpenFreeMapView({
    super.key,
    this.userLocation,
    this.incidentLocation,
    this.ambulanceLocation,
    this.heading,
    this.ambulanceId,
    this.routeWaypoints,
    this.nearbyHospitals,
    this.nearbyAmbulances,
    this.style = OpenFreeMapStyle.bright,
    this.isPickerMode = false,
    this.showSearchRadar = false,
    this.recenterTrigger = 0,
    this.onLocationPicked,
  });

  static DateTime? _suppressUntil;

  static void suppressClicks([int ms = 600]) {
    _suppressUntil = DateTime.now().add(Duration(milliseconds: ms));
  }

  static void setUIHovered(bool hovered) {
    // No-op for non-web platforms
  }

  @override
  State<PlatformOpenFreeMapView> createState() => _PlatformOpenFreeMapViewState();
}

class _PlatformOpenFreeMapViewState extends State<PlatformOpenFreeMapView>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PlatformOpenFreeMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isRecenter = oldWidget.recenterTrigger != widget.recenterTrigger;
    final latChanged = oldWidget.incidentLocation?.latitude != widget.incidentLocation?.latitude ||
        oldWidget.incidentLocation?.longitude != widget.incidentLocation?.longitude;

    if (isRecenter || (latChanged && widget.isPickerMode)) {
      final targetLat = widget.incidentLocation?.latitude ?? MapConstants.defaultLatitude;
      final targetLng = widget.incidentLocation?.longitude ?? MapConstants.defaultLongitude;
      _mapController.move(
        LatLng(targetLat, targetLng),
        widget.isPickerMode ? MapConstants.pickerZoom : MapConstants.trackingZoom,
      );
    }
  }

  String _getTileUrl(OpenFreeMapStyle style) {
    switch (style) {
      case OpenFreeMapStyle.dark:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case OpenFreeMapStyle.fiord:
        return 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png';
      case OpenFreeMapStyle.positron:
        return 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png';
      case OpenFreeMapStyle.liberty:
        return 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
      case OpenFreeMapStyle.bright:
      case OpenFreeMapStyle.threeD:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> _getSubdomains(OpenFreeMapStyle style) {
    switch (style) {
      case OpenFreeMapStyle.liberty:
        return const ['a', 'b'];
      case OpenFreeMapStyle.positron:
      case OpenFreeMapStyle.fiord:
        return const ['a', 'b', 'c'];
      case OpenFreeMapStyle.dark:
      case OpenFreeMapStyle.bright:
      case OpenFreeMapStyle.threeD:
        return const [];
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    if (!widget.isPickerMode || widget.onLocationPicked == null) return;
    if (PlatformOpenFreeMapView._suppressUntil != null &&
        DateTime.now().isBefore(PlatformOpenFreeMapView._suppressUntil!)) {
      return;
    }

    widget.onLocationPicked!(
      LocationData(
        latitude: point.latitude,
        longitude: point.longitude,
        timestamp: DateTime.now(),
        isManualOverride: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentLat = widget.incidentLocation?.latitude ?? MapConstants.defaultLatitude;
    final incidentLng = widget.incidentLocation?.longitude ?? MapConstants.defaultLongitude;
    final initialCenter = LatLng(incidentLat, incidentLng);
    final initialZoom = widget.isPickerMode ? MapConstants.pickerZoom : MapConstants.trackingZoom;

    final tileUrl = _getTileUrl(widget.style);
    final subdomains = _getSubdomains(widget.style);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: 3.0,
            maxZoom: 19.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: _handleTap,
          ),
          children: [
            // 1. Live Raster Map Tiles (OpenStreetMap / CartoDB)
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: subdomains,
              userAgentPackageName: 'com.uyirkappan.bystander.uyirkappan_bystander',
              maxZoom: 19,
              tileBuilder: widget.style == OpenFreeMapStyle.dark
                  ? (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          -0.8, 0, 0, 0, 255,
                          0, -0.8, 0, 0, 255,
                          0, 0, -0.8, 0, 255,
                          0, 0, 0, 1, 0,
                        ]),
                        child: tileWidget,
                      );
                    }
                  : null,
            ),

            // 2. Search Radar Waves (when looking for nearest responder)
            if (widget.showSearchRadar)
              MarkerLayer(
                markers: [
                  Marker(
                    point: initialCenter,
                    width: 140,
                    height: 140,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 0.4 + (_pulseController.value * 0.9);
                        final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                        return Center(
                          child: Container(
                            width: 140 * scale,
                            height: 140 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.statusSearching.withValues(alpha: opacity * 0.8),
                                width: 2.5,
                              ),
                              color: AppColors.statusSearching.withValues(alpha: opacity * 0.12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            // 3. User GPS Location Marker
            if (widget.userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude),
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),

            // 4. Nearby Hospital POI Markers
            if (widget.nearbyHospitals != null && widget.nearbyHospitals!.isNotEmpty)
              MarkerLayer(
                markers: widget.nearbyHospitals!.map((h) {
                  return Marker(
                    point: LatLng(h.latitude, h.longitude),
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 16),
                    ),
                  );
                }).toList(),
              ),

            // 5. Nearby Standby Ambulances (idle/patrolling)
            if (widget.nearbyAmbulances != null && widget.nearbyAmbulances!.isNotEmpty)
              MarkerLayer(
                markers: widget.nearbyAmbulances!.map((amb) {
                  return Marker(
                    point: LatLng(amb.latitude, amb.longitude),
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 15),
                    ),
                  );
                }).toList(),
              ),

            // 6. Incident / Pickup Point Marker
            MarkerLayer(
              markers: [
                Marker(
                  point: initialCenter,
                  width: 90,
                  height: 90,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.7);
                      final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.emergencyRed.withValues(alpha: opacity * 0.4),
                              ),
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.emergencyRed,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emergencyRed.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.isPickerMode ? 'PICKUP POINT' : 'INCIDENT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        // Bottom style / provider attribution badge
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'OpenFreeMap (${widget.style.name}) • OpenStreetMap',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Quick zoom in/out & recenter buttons for mobile touch convenience
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapActionButton(
                icon: Icons.add_rounded,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom + 1);
                },
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: Icons.remove_rounded,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, zoom - 1);
                },
              ),
              const SizedBox(height: 6),
              _buildMapActionButton(
                icon: Icons.my_location_rounded,
                onPressed: () {
                  _mapController.move(initialCenter, initialZoom);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
