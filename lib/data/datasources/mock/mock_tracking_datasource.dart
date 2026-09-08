import 'dart:async';
import 'dart:math' as math;
import '../../models/eta_model.dart';
import '../../models/tracking_model.dart';
import '../../../core/services/road_routing_service.dart';
import '../../../core/utils/map_route_geometry.dart';
import '../../../domain/entities/location_data.dart';
import '../../../domain/entities/nearby_poi.dart';
import '../../../domain/entities/request_status.dart';
import '../tracking_datasource.dart';

import '../remote/socket_service.dart';

class _AssignedUnit {
  final String ambulanceId;
  final String? driverName;
  final String? driverPhone;
  double latitude;
  double longitude;
  double destLatitude;
  double destLongitude;
  double heading;
  int etaMinutes;
  double speedKmH;
  RequestStatus status;
  List<LocationData> routePoints;
  int currentStepIndex;
  String? hospitalName;
  double? hospitalLatitude;
  double? hospitalLongitude;
  int currentTick;
  int totalTicks;
  bool phase2TransitionScheduled = false;
  bool phase3TransitionScheduled = false;

  _AssignedUnit({
    required this.ambulanceId,
    this.driverName,
    this.driverPhone,
    required this.latitude,
    required this.longitude,
    required this.destLatitude,
    required this.destLongitude,
    required this.heading,
    this.etaMinutes = 6,
    this.speedKmH = 48.0,
    this.status = RequestStatus.enRouteToPatient,
    required this.routePoints,
    this.currentStepIndex = 0,
    this.hospitalName,
    this.hospitalLatitude,
    this.hospitalLongitude,
    this.currentTick = 0,
    this.totalTicks = 10,
  });
}

/// Simulated Tracking DataSource for realistic real-time Module 1 demonstration.
class MockTrackingDataSource implements TrackingDataSource {
  final SocketService? socketService;
  final Map<String, StreamController<TrackingModel>> _trackingControllers = {};
  final Map<String, StreamController<EtaModel>> _etaControllers = {};
  final Map<String, _AssignedUnit> _assignments = {};
  final Map<String, Timer> _streamTimers = {};
  final Map<String, List<Timer>> _unitTimers = {};
  final List<Timer> _activeTimers = [];

  final RoadRoutingService routingService;

  /// Callback when simulation phases transition automatically
  void Function(String requestId, RequestStatus status)? onStatusTransition;

  MockTrackingDataSource({
    this.socketService,
    RoadRoutingService? routingService,
  }) : routingService = routingService ?? RoadRoutingService();

  /// Binds a dispatched unit from a fixed base station to the emergency scene.
  void assignUnit({
    required String requestId,
    required String ambulanceId,
    String? driverName,
    String? driverPhone,
    required double startLatitude,
    required double startLongitude,
    required double destLatitude,
    required double destLongitude,
    String? hospitalName,
    double? hospitalLatitude,
    double? hospitalLongitude,
    int routeSteps = 14,
  }) {
    final start = LocationData(
      latitude: startLatitude,
      longitude: startLongitude,
      timestamp: DateTime.now(),
    );
    final dest = LocationData(
      latitude: destLatitude,
      longitude: destLongitude,
      timestamp: DateTime.now(),
    );

    final rawRoute = MapRouteGeometry.buildSimulatedRoute(from: start, to: dest);
    final smoothPath = MapRouteGeometry.interpolatePath(rawRoute, totalSteps: 36);

    final initialHeading = MapRouteGeometry.headingDegrees(start, smoothPath.length > 1 ? smoothPath[1] : dest);
    final distKm = NearbyEmergencyService.distanceKm(startLatitude, startLongitude, destLatitude, destLongitude);
    final eta = math.max(2, (distKm * 1.5).round());

    _assignments[requestId] = _AssignedUnit(
      ambulanceId: ambulanceId,
      driverName: driverName ?? 'Karthik Raja (Paramedic Lead)',
      driverPhone: driverPhone ?? '+91 98401 23456',
      latitude: startLatitude,
      longitude: startLongitude,
      destLatitude: destLatitude,
      destLongitude: destLongitude,
      heading: initialHeading,
      etaMinutes: eta,
      speedKmH: 48.0,
      status: RequestStatus.enRouteToPatient,
      routePoints: smoothPath,
      currentStepIndex: 0,
      hospitalName: hospitalName,
      hospitalLatitude: hospitalLatitude,
      hospitalLongitude: hospitalLongitude,
      currentTick: 0,
      totalTicks: routeSteps,
    );

    _emit(requestId);

    // Asynchronously upgrade to 100% real road network geometry via OSRM
    _upgradeToRealRoadRoute(requestId, start, dest, totalSteps: routeSteps);
  }

  Future<void> _upgradeToRealRoadRoute(
    String requestId,
    LocationData from,
    LocationData to, {
    int totalSteps = 10,
  }) async {
    try {
      final roadResult = await routingService.fetchRoadRoute(from: from, to: to);
      final unit = _assignments[requestId];
      if (unit != null && roadResult.waypoints.isNotEmpty) {
        // High-resolution road waypoints snapped directly to OSM street network
        final currentLoc = LocationData(
          latitude: unit.latitude,
          longitude: unit.longitude,
          timestamp: DateTime.now(),
        );

        final List<LocationData> roadPath;
        if (roadResult.waypoints.length >= 12) {
          roadPath = [currentLoc, ...roadResult.waypoints.skip(1)];
        } else {
          roadPath = MapRouteGeometry.interpolatePath([currentLoc, ...roadResult.waypoints], totalSteps: 36);
        }

        unit.routePoints = roadPath;
        unit.etaMinutes = roadResult.estimatedMinutes;
        if (roadPath.length > 1) {
          unit.heading = MapRouteGeometry.headingDegrees(currentLoc, roadPath[1], unit.heading);
        }
        _emit(requestId);
      }
    } catch (_) {}
  }

  /// Transitions the assigned unit to hospital transit mode (patient onboard -> en route to hospital).
  void navigateToHospital({
    required String requestId,
    required double hospitalLatitude,
    required double hospitalLongitude,
    required String hospitalName,
    int routeSteps = 24,
  }) {
    final unit = _assignments[requestId];
    if (unit == null) return;

    // Start at the incident pickup location where the ambulance is currently stationed with patient
    final start = LocationData(
      latitude: unit.destLatitude,
      longitude: unit.destLongitude,
      timestamp: DateTime.now(),
    );
    final dest = LocationData(
      latitude: hospitalLatitude,
      longitude: hospitalLongitude,
      timestamp: DateTime.now(),
    );

    final rawRoute = MapRouteGeometry.buildSimulatedRoute(from: start, to: dest);
    final smoothPath = MapRouteGeometry.interpolatePath(rawRoute, totalSteps: 36);

    unit.latitude = unit.destLatitude;
    unit.longitude = unit.destLongitude;
    unit.destLatitude = hospitalLatitude;
    unit.destLongitude = hospitalLongitude;
    unit.hospitalName = hospitalName;
    unit.routePoints = smoothPath;
    unit.currentStepIndex = 0;
    unit.currentTick = 0;
    unit.totalTicks = routeSteps;
    unit.status = RequestStatus.enRouteToHospital;
    unit.speedKmH = 54.0; // Higher speed on green corridor to hospital
    if (smoothPath.length > 1) {
      unit.heading = MapRouteGeometry.headingDegrees(smoothPath[0], smoothPath[1], unit.heading);
    }

    final distKm = NearbyEmergencyService.distanceKm(unit.latitude, unit.longitude, hospitalLatitude, hospitalLongitude);
    unit.etaMinutes = math.max(2, (distKm * 1.3).round());

    _emit(requestId);

    // Asynchronously upgrade to real road polyline to hospital
    _upgradeToRealRoadRoute(requestId, start, dest, totalSteps: routeSteps);
  }

  /// Adjusts simulated road traffic for Scenario E (dynamic traffic congestion -> ETA increases)
  void applyTrafficSurge(String requestId, {double trafficMultiplier = 1.6}) {
    final unit = _assignments[requestId];
    if (unit == null) return;
    unit.speedKmH = math.max(20.0, unit.speedKmH / trafficMultiplier);
    unit.etaMinutes = (unit.etaMinutes * trafficMultiplier).round();
    _emit(requestId);
  }

  /// Recalculates an alternative detour route for Scenario F (road closure)
  Future<void> recalculateDetour(String requestId) async {
    final unit = _assignments[requestId];
    if (unit == null) return;

    final current = LocationData(
      latitude: unit.latitude,
      longitude: unit.longitude,
      timestamp: DateTime.now(),
    );
    final dest = LocationData(
      latitude: unit.destLatitude,
      longitude: unit.destLongitude,
      timestamp: DateTime.now(),
    );

    // Compute midpoint detour offset by 0.006 degrees (~600m) to simulate diverting around blocked street
    final detourMidpoint = LocationData(
      latitude: (current.latitude + dest.latitude) / 2 + 0.005,
      longitude: (current.longitude + dest.longitude) / 2 - 0.005,
      timestamp: DateTime.now(),
    );

    final leg1 = await routingService.fetchRoadRoute(from: current, to: detourMidpoint);
    final leg2 = await routingService.fetchRoadRoute(from: detourMidpoint, to: dest);
    final combinedWaypoints = [...leg1.waypoints, ...leg2.waypoints];

    unit.routePoints = MapRouteGeometry.interpolatePath(combinedWaypoints, totalSteps: 24);
    unit.currentStepIndex = 0;
    unit.currentTick = (unit.totalTicks * 0.35).round(); // Seamlessly resume along detour
    unit.etaMinutes = leg1.estimatedMinutes + leg2.estimatedMinutes;
    _emit(requestId);
  }

  /// Sets the operational status of the unit (e.g. arrivedAtPatient, patientOnboard, arrivedAtHospital).
  void setUnitStatus(String requestId, RequestStatus status) {
    final unit = _assignments[requestId];
    if (unit == null) return;

    unit.status = status;
    if (status == RequestStatus.arrivedAtPatient || status == RequestStatus.arrivedAtHospital) {
      unit.speedKmH = 0.0;
      unit.etaMinutes = 0;
      unit.latitude = unit.destLatitude;
      unit.longitude = unit.destLongitude;
      unit.currentTick = unit.totalTicks;
    } else if (status == RequestStatus.enRouteToHospital) {
      unit.speedKmH = 54.0;
    } else if (status == RequestStatus.enRouteToPatient) {
      unit.speedKmH = 48.0;
    }
    _emit(requestId);
  }

  void clearUnit(String requestId) {
    _streamTimers[requestId]?.cancel();
    _streamTimers.remove(requestId);
    final timers = _unitTimers.remove(requestId);
    if (timers != null) {
      for (final t in timers) {
        t.cancel();
      }
    }
    _assignments.remove(requestId);
  }

  void clearAll() {
    for (final timer in _streamTimers.values) {
      timer.cancel();
    }
    _streamTimers.clear();
    for (final timers in _unitTimers.values) {
      for (final t in timers) {
        t.cancel();
      }
    }
    _unitTimers.clear();
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    _assignments.clear();
  }

  @override
  Future<TrackingModel?> getTrackingInfo(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _buildSnapshot(requestId);
  }

  @override
  Future<EtaModel?> getEta(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _buildEta(requestId);
  }

  @override
  Stream<TrackingModel> watchTrackingUpdates(String requestId) {
    if (!_trackingControllers.containsKey(requestId)) {
      _trackingControllers[requestId] = StreamController<TrackingModel>.broadcast();
      _startSimulatedTelemetryStream(requestId);
    }
    final snapshot = _buildSnapshot(requestId);
    if (snapshot != null) {
      Timer.run(() {
        if (_trackingControllers.containsKey(requestId) &&
            !_trackingControllers[requestId]!.isClosed) {
          _trackingControllers[requestId]!.add(snapshot);
        }
      });
    }
    return _trackingControllers[requestId]!.stream;
  }

  @override
  Stream<EtaModel> watchEtaUpdates(String requestId) {
    if (!_etaControllers.containsKey(requestId)) {
      _etaControllers[requestId] = StreamController<EtaModel>.broadcast();
    }
    return _etaControllers[requestId]!.stream;
  }

  /// Runs continuous 750ms ticks advancing the ambulance smoothly along road waypoints.
  void _startSimulatedTelemetryStream(String requestId) {
    _streamTimers[requestId]?.cancel();

    final timer = Timer.periodic(const Duration(milliseconds: 750), (t) {
      if (!_trackingControllers.containsKey(requestId) ||
          _trackingControllers[requestId]!.isClosed) {
        t.cancel();
        _streamTimers.remove(requestId);
        return;
      }
      final unit = _assignments[requestId];
      if (unit == null) return;

      // Only advance position when actively traveling on the road
      final isMoving = unit.status == RequestStatus.enRouteToPatient ||
          unit.status == RequestStatus.enRouteToHospital;

      if (isMoving && unit.routePoints.isNotEmpty) {
        if (unit.currentTick < unit.totalTicks) {
          unit.currentTick++;
          final progress = (unit.currentTick / unit.totalTicks).clamp(0.0, 1.0);

          final snappedPoint = MapRouteGeometry.getPointAtProgress(
            unit.routePoints,
            progress,
            fallbackHeading: unit.heading,
          );

          unit.latitude = snappedPoint.latitude;
          unit.longitude = snappedPoint.longitude;
          unit.heading = snappedPoint.heading ?? unit.heading;

          // Compute remaining distance in meters
          final remainingDistKm = NearbyEmergencyService.distanceKm(
            unit.latitude,
            unit.longitude,
            unit.destLatitude,
            unit.destLongitude,
          );
          unit.etaMinutes = math.max(1, (remainingDistKm * 1.4).round());

          // Fluctuate speed slightly around 48 km/h for realistic GPS telemetry
          final jitter = (math.Random().nextDouble() - 0.5) * 4;
          unit.speedKmH = math.max(38.0, math.min(62.0, (unit.status == RequestStatus.enRouteToHospital ? 54.0 : 48.0) + jitter));
        } else {
          // Reached destination for current phase
          unit.latitude = unit.destLatitude;
          unit.longitude = unit.destLongitude;
          unit.speedKmH = 0.0;
          unit.etaMinutes = 0;

          if (unit.status == RequestStatus.enRouteToPatient && !unit.phase2TransitionScheduled) {
            unit.phase2TransitionScheduled = true;
            unit.status = RequestStatus.arrivedAtPatient;
            _emit(requestId);
            onStatusTransition?.call(requestId, RequestStatus.arrivedAtPatient);

            // Phase 2: Paramedics stabilize patient on scene (3.5s dwell time)
            final timer2 = Timer(const Duration(milliseconds: 3500), () {
              final curUnit = _assignments[requestId];
              if (curUnit == null || curUnit.status != RequestStatus.arrivedAtPatient) return;

              curUnit.status = RequestStatus.patientOnboard;
              _emit(requestId);
              onStatusTransition?.call(requestId, RequestStatus.patientOnboard);

              // Phase 3: Patient onboard -> Proceed to hospital (1.5s after onboard)
              final timer3 = Timer(const Duration(milliseconds: 1500), () {
                final curUnit2 = _assignments[requestId];
                if (curUnit2 == null || curUnit2.status != RequestStatus.patientOnboard) return;

                final hospLat = curUnit2.hospitalLatitude ?? (curUnit2.latitude + 0.015);
                final hospLng = curUnit2.hospitalLongitude ?? (curUnit2.longitude - 0.015);
                final hospName = curUnit2.hospitalName ?? 'Emergency Care Hospital';

                navigateToHospital(
                  requestId: requestId,
                  hospitalLatitude: hospLat,
                  hospitalLongitude: hospLng,
                  hospitalName: hospName,
                  routeSteps: 14,
                );
                onStatusTransition?.call(requestId, RequestStatus.enRouteToHospital);
              });

              _unitTimers.putIfAbsent(requestId, () => []).add(timer3);
              _activeTimers.add(timer3);
            });

            _unitTimers.putIfAbsent(requestId, () => []).add(timer2);
            _activeTimers.add(timer2);
          } else if (unit.status == RequestStatus.enRouteToHospital && !unit.phase3TransitionScheduled) {
            unit.phase3TransitionScheduled = true;
            unit.status = RequestStatus.arrivedAtHospital;
            _emit(requestId);
            onStatusTransition?.call(requestId, RequestStatus.arrivedAtHospital);

            // Phase 4: Arrived at Hospital -> Completed / Resolved (4.0s dwell time)
            final timer4 = Timer(const Duration(milliseconds: 4000), () {
              final curUnit3 = _assignments[requestId];
              if (curUnit3 == null || curUnit3.status != RequestStatus.arrivedAtHospital) return;

              curUnit3.status = RequestStatus.completed;
              _emit(requestId);
              onStatusTransition?.call(requestId, RequestStatus.completed);
            });

            _unitTimers.putIfAbsent(requestId, () => []).add(timer4);
            _activeTimers.add(timer4);
          }
        }
      }

      _emit(requestId);
    });

    _activeTimers.add(timer);
    _streamTimers[requestId] = timer;
  }

  void _emit(String requestId) {
    final tracking = _buildSnapshot(requestId);
    if (tracking == null) return;
    final controller = _trackingControllers[requestId];
    if (controller != null && !controller.isClosed) {
      controller.add(tracking);
    }
    final etaController = _etaControllers[requestId];
    if (etaController != null && !etaController.isClosed && tracking.eta is EtaModel) {
      etaController.add(tracking.eta as EtaModel);
    }

    // Emit real-time Socket.IO events for live tracking and dynamic ETA
    if (socketService != null) {
      final unit = _assignments[requestId];
      if (unit != null) {
        socketService!.emitSimulatedEvent('AMBULANCE_LOCATION_UPDATED', {
          'requestId': requestId,
          'ambulanceId': unit.ambulanceId,
          'location': {'latitude': unit.latitude, 'longitude': unit.longitude},
          'status': unit.status.code,
        });

        final remainingDistKm = NearbyEmergencyService.distanceKm(
          unit.latitude,
          unit.longitude,
          unit.destLatitude,
          unit.destLongitude,
        );
        socketService!.emitSimulatedEvent('ETA_UPDATED', {
          'requestId': requestId,
          'etaMinutes': unit.etaMinutes,
          'distanceKm': remainingDistKm.toStringAsFixed(1),
        });
      }
    }
  }

  TrackingModel? _buildSnapshot(String requestId) {
    final unit = _assignments[requestId];
    if (unit == null) {
      return null;
    }

    final remainingDistKm = NearbyEmergencyService.distanceKm(
      unit.latitude,
      unit.longitude,
      unit.destLatitude,
      unit.destLongitude,
    );
    final distanceMeters = remainingDistKm * 1000.0;

    String corridorNote = 'Green Corridor Active';
    if (unit.status == RequestStatus.enRouteToHospital) {
      corridorNote = 'Hospital Trauma Corridor: ${unit.hospitalName ?? 'Emergency ICU'}';
    } else if (unit.status == RequestStatus.arrivedAtPatient) {
      corridorNote = 'Paramedic Unit On Scene';
    } else if (unit.status == RequestStatus.patientOnboard) {
      corridorNote = 'Patient Stabilized & Loaded';
    }

    return TrackingModel(
      ambulanceId: unit.ambulanceId,
      requestId: requestId,
      latitude: unit.latitude,
      longitude: unit.longitude,
      speedKmH: unit.speedKmH,
      headingDegrees: unit.heading,
      timestamp: DateTime.now(),
      status: unit.status,
      eta: EtaModel(
        estimatedMinutes: unit.etaMinutes,
        distanceMeters: distanceMeters,
        lastCalculatedAt: DateTime.now(),
        trafficCondition: corridorNote,
      ),
      vehicleNumber: 'TN-01-AMB-${unit.ambulanceId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0')}',
      driverName: unit.driverName ?? 'Karthik Raja (Paramedic Lead)',
      driverPhone: unit.driverPhone ?? '+91 98401 23456',
      routeWaypoints: unit.routePoints,
    );
  }

  EtaModel _buildEta(String requestId) {
    final unit = _assignments[requestId];
    final remainingDistKm = unit != null
        ? NearbyEmergencyService.distanceKm(unit.latitude, unit.longitude, unit.destLatitude, unit.destLongitude)
        : 2.0;
    return EtaModel(
      estimatedMinutes: unit?.etaMinutes ?? 4,
      distanceMeters: remainingDistKm * 1000.0,
      lastCalculatedAt: DateTime.now(),
      trafficCondition: 'Green Corridor Active',
    );
  }

  void dispose() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    for (final c in _trackingControllers.values) {
      c.close();
    }
    _trackingControllers.clear();
    for (final c in _etaControllers.values) {
      c.close();
    }
    _etaControllers.clear();
    _assignments.clear();
  }
}
