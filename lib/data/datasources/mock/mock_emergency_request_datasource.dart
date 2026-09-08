import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../models/emergency_request_model.dart';
import '../../../domain/entities/nearby_poi.dart';
import '../../../domain/entities/request_status.dart';
import '../emergency_request_datasource.dart';
import '../remote/socket_service.dart';
import 'mock_tracking_datasource.dart';

/// Clean Local Mock Emergency Request Data Source.
/// Emulates realistic asynchronous backend response and status progression.
class MockEmergencyRequestDataSource implements EmergencyRequestDataSource {
  final Map<String, EmergencyRequestModel> _inMemoryStore = {};
  final Map<String, StreamController<EmergencyRequestModel>> _streamControllers = {};
  final List<Timer> _activeTimers = [];
  final SocketService? socketService;
  final MockTrackingDataSource? trackingDataSource;

  MockEmergencyRequestDataSource({
    this.socketService,
    this.trackingDataSource,
  }) {
    _initTrackingListener();
  }

  void _initTrackingListener() {
    trackingDataSource?.onStatusTransition = (requestId, newStatus) {
      final current = _inMemoryStore[requestId];
      if (current != null && (current.status.isActive || newStatus == RequestStatus.completed)) {
        final updated = current.copyWith(
          status: newStatus,
          t6AmbulanceArrived: newStatus == RequestStatus.arrivedAtPatient
              ? (current.t6AmbulanceArrived ?? DateTime.now())
              : current.t6AmbulanceArrived,
          completedAt: newStatus == RequestStatus.completed ? DateTime.now() : current.completedAt,
        );
        _updateAndEmit(updated);
        socketService?.emitSimulatedEvent('STATUS_UPDATED', {
          'requestId': requestId,
          'status': newStatus.code,
          'ambulanceId': current.assignedAmbulanceId ?? 'AMB-TN-01-108',
        });
      }
    };
  }

  @override
  Future<EmergencyRequestModel> createEmergencyRequest(EmergencyRequestModel request) async {
    _cancelTimers();

    // Emulate initial network latency
    await Future.delayed(const Duration(milliseconds: 350));

    final String generatedId = 'UK-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final createdModel = EmergencyRequestModel(
      requestId: generatedId,
      requesterId: request.requesterId.isNotEmpty
          ? request.requesterId
          : 'BYSTANDER-${const Uuid().v4().substring(0, 4)}',
      emergencyType: request.emergencyType,
      victimCount: request.victimCount,
      emergencyLocation: request.emergencyLocation,
      requesterLocation: request.requesterLocation,
      createdAt: now,
      status: RequestStatus.searching,
      additionalNotes: request.additionalNotes,
      t0UserPressed: request.t0UserPressed ?? now,
      t1RequestReceived: now,
    );

    _inMemoryStore[generatedId] = createdModel;

    socketService?.emitSimulatedEvent('EMERGENCY_CREATED', {
      'requestId': generatedId,
      'status': 'SEARCHING',
    });

    // Start clean status lifecycle progression
    _startDispatchLifecycle(generatedId);

    return createdModel;
  }

  void _startDispatchLifecycle(String requestId) {
    // Stage 1: 800ms -> Assigned (Unit assigned by dispatch center)
    _activeTimers.add(
      Timer(const Duration(milliseconds: 800), () {
        final current = _inMemoryStore[requestId];
        if (current == null || current.status == RequestStatus.cancelled) return;

        // Find nearest hospital for destination
        final hospitals = NearbyEmergencyService.getHospitalsAround(
          current.emergencyLocation.latitude,
          current.emergencyLocation.longitude,
        );
        final assignedHospital = hospitals.isNotEmpty
            ? hospitals.first
            : null;
        final hospName = assignedHospital?.name ?? 'Vijaya Hospital';
        final hospLat = assignedHospital?.latitude ?? (current.emergencyLocation.latitude + 0.015);
        final hospLng = assignedHospital?.longitude ?? (current.emergencyLocation.longitude - 0.015);

        final standbyAmbulances = NearbyEmergencyService.getStandbyAmbulancesAround(
          current.emergencyLocation.latitude,
          current.emergencyLocation.longitude,
        );
        final nearestAmb = standbyAmbulances.isNotEmpty ? standbyAmbulances.first : null;
        final startLat = nearestAmb?.latitude ?? (current.emergencyLocation.latitude + 0.012);
        final startLng = nearestAmb?.longitude ?? (current.emergencyLocation.longitude + 0.012);

        // Bind vehicle tracking
        trackingDataSource?.assignUnit(
          requestId: requestId,
          ambulanceId: 'AMB-TN-01-108',
          driverName: 'Suresh Kumar',
          driverPhone: '+91 98401 23456',
          startLatitude: startLat,
          startLongitude: startLng,
          destLatitude: current.emergencyLocation.latitude,
          destLongitude: current.emergencyLocation.longitude,
          hospitalName: hospName,
          hospitalLatitude: hospLat,
          hospitalLongitude: hospLng,
          routeSteps: 14,
        );

        final updated = current.copyWith(
          status: RequestStatus.assigned,
          assignedAmbulanceId: 'AMB-TN-01-108',
          assignedDriverName: 'Suresh Kumar',
          driverPhone: '+91 98401 23456',
          hospitalDestination: hospName,
          t2MatchingCompleted: DateTime.now(),
        );

        _updateAndEmit(updated);

        socketService?.emitSimulatedEvent('AMBULANCE_ASSIGNED', {
          'requestId': requestId,
          'ambulanceId': 'AMB-TN-01-108',
          'driverName': 'Suresh Kumar',
          'driverPhone': '+91 98401 23456',
          'hospitalDestination': hospName,
        });

        // Stage 2: 1200ms later -> Driver accepts & en route to patient
        _activeTimers.add(
          Timer(const Duration(milliseconds: 1200), () {
            final assignedState = _inMemoryStore[requestId];
            if (assignedState == null || assignedState.status == RequestStatus.cancelled) return;

            final enRoute = assignedState.copyWith(
              status: RequestStatus.enRouteToPatient,
              t4DriverAccepted: DateTime.now(),
              t5AmbulanceStarted: DateTime.now(),
            );

            _updateAndEmit(enRoute);

            socketService?.emitSimulatedEvent('STATUS_UPDATED', {
              'requestId': requestId,
              'status': 'EN_ROUTE_TO_PATIENT',
              'ambulanceId': 'AMB-TN-01-108',
            });
          }),
        );
      }),
    );
  }

  @override
  Future<EmergencyRequestModel> getEmergencyRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final request = _inMemoryStore[requestId];
    if (request != null) {
      return request;
    }
    throw Exception('Emergency request $requestId not found in mock store');
  }

  @override
  Future<RequestStatus> getRequestStatus(String requestId) async {
    final request = await getEmergencyRequest(requestId);
    return request.status;
  }

  @override
  Future<EmergencyRequestModel> cancelEmergencyRequest(String requestId, {String? reason}) async {
    _cancelTimers();
    trackingDataSource?.clearUnit(requestId);
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = await getEmergencyRequest(requestId);
    final cancelled = existing.copyWith(
      status: RequestStatus.cancelled,
      additionalNotes: reason != null ? 'Cancelled: $reason' : existing.additionalNotes,
    );

    _updateAndEmit(cancelled);

    socketService?.emitSimulatedEvent('STATUS_UPDATED', {
      'requestId': requestId,
      'status': 'CANCELLED',
    });

    return cancelled;
  }

  @override
  Stream<EmergencyRequestModel> watchRequestUpdates(String requestId) {
    if (!_streamControllers.containsKey(requestId)) {
      _streamControllers[requestId] = StreamController<EmergencyRequestModel>.broadcast();
    }

    final current = _inMemoryStore[requestId];
    if (current != null) {
      Timer.run(() {
        final ctrl = _streamControllers[requestId];
        if (ctrl != null && !ctrl.isClosed) {
          ctrl.add(current);
        }
      });
    }

    return _streamControllers[requestId]!.stream;
  }

  void _updateAndEmit(EmergencyRequestModel updated) {
    _inMemoryStore[updated.requestId] = updated;
    final ctrl = _streamControllers[updated.requestId];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(updated);
    }
  }

  void _cancelTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  void dispose() {
    _cancelTimers();
    for (final ctrl in _streamControllers.values) {
      ctrl.close();
    }
    _streamControllers.clear();
    _inMemoryStore.clear();
  }
}
