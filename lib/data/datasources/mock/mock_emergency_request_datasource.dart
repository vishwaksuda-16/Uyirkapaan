import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../models/emergency_request_model.dart';
import '../../../domain/entities/request_status.dart';
import '../emergency_request_datasource.dart';

/// Available demonstration scenarios for college viva / paper / system testing.
enum SimulationScenarioType {
  normalDispatch,
  driverRejectionWithFallback,
  driverTimeoutWithFallback,
  noAmbulanceAvailable,
  trackingIntegrationDemo,
}

/// Simulated Backend Data Source.
/// Emulates asynchronous network responses, state transitions, dispatch latency,
/// and cascading fallback events without bypassing the architecture.
class MockEmergencyRequestDataSource implements EmergencyRequestDataSource {
  final Map<String, EmergencyRequestModel> _inMemoryStore = {};
  final Map<String, StreamController<EmergencyRequestModel>> _streamControllers = {};
  final List<Timer> _activeTimers = [];

  SimulationScenarioType activeScenario = SimulationScenarioType.normalDispatch;
  bool isFastSimulation = true;

  @override
  Future<EmergencyRequestModel> createEmergencyRequest(EmergencyRequestModel request) async {
    // Simulate real asynchronous network latency (500ms - 1000ms)
    await Future.delayed(const Duration(milliseconds: 600));

    final String generatedId = 'UK-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final createdModel = EmergencyRequestModel(
      requestId: generatedId,
      requesterId: request.requesterId.isNotEmpty ? request.requesterId : 'BYSTANDER-${const Uuid().v4().substring(0, 4)}',
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

    // Start lifecycle simulation according to the selected scenario
    _startScenarioLifecycle(generatedId, activeScenario);

    return createdModel;
  }

  @override
  Future<EmergencyRequestModel> getEmergencyRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
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
    await Future.delayed(const Duration(milliseconds: 300));
    final existing = await getEmergencyRequest(requestId);
    final cancelled = existing.copyWith(
      status: RequestStatus.cancelled,
      additionalNotes: reason != null ? 'Cancelled: $reason' : existing.additionalNotes,
    ) as EmergencyRequestModel;

    _updateAndEmit(cancelled);
    _cancelTimers();
    return cancelled;
  }

  @override
  Stream<EmergencyRequestModel> watchRequestUpdates(String requestId) {
    if (!_streamControllers.containsKey(requestId)) {
      _streamControllers[requestId] = StreamController<EmergencyRequestModel>.broadcast();
    }

    // Immediately push current state if available
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

  /// Sets the active simulation scenario for demonstrations.
  void setScenario(SimulationScenarioType scenario) {
    activeScenario = scenario;
  }

  void _startScenarioLifecycle(String requestId, SimulationScenarioType scenario) {
    final baseDelay = isFastSimulation ? const Duration(seconds: 3) : const Duration(seconds: 8);

    switch (scenario) {
      case SimulationScenarioType.normalDispatch:
      case SimulationScenarioType.trackingIntegrationDemo:
        _runNormalScenario(requestId, baseDelay);
        break;
      case SimulationScenarioType.driverRejectionWithFallback:
        _runDriverRejectionScenario(requestId, baseDelay);
        break;
      case SimulationScenarioType.driverTimeoutWithFallback:
        _runDriverTimeoutScenario(requestId, baseDelay);
        break;
      case SimulationScenarioType.noAmbulanceAvailable:
        _runNoAmbulanceScenario(requestId, baseDelay);
        break;
    }
  }

  void _runNormalScenario(String requestId, Duration baseDelay) {
    // 1. Searching -> Assigned
    _schedule(baseDelay, () {
      final req = _inMemoryStore[requestId];
      if (req == null || !req.status.isActive) return;

      final now = DateTime.now();
      final updated = req.copyWith(
        status: RequestStatus.assigned,
        assignedAmbulanceId: 'AMB-CH-042',
        assignedDriverName: 'Karthik Raja',
        driverPhone: '+91 98401 23456',
        t2MatchingCompleted: now,
        t3AssignmentSent: now,
      ) as EmergencyRequestModel;
      _updateAndEmit(updated);

      // 2. Assigned -> Driver Accepted
      _schedule(baseDelay, () {
        final req2 = _inMemoryStore[requestId];
        if (req2 == null || !req2.status.isActive) return;

        final now2 = DateTime.now();
        final updated2 = req2.copyWith(
          status: RequestStatus.accepted,
          t4DriverAccepted: now2,
        ) as EmergencyRequestModel;
        _updateAndEmit(updated2);

        // 3. Accepted -> En Route to Patient
        _schedule(baseDelay, () {
          final req3 = _inMemoryStore[requestId];
          if (req3 == null || !req3.status.isActive) return;

          final now3 = DateTime.now();
          final updated3 = req3.copyWith(
            status: RequestStatus.enRouteToPatient,
            t5AmbulanceStarted: now3,
          ) as EmergencyRequestModel;
          _updateAndEmit(updated3);

          // 4. En Route -> Arrived at Scene
          _schedule(baseDelay * 1.5, () {
            final req4 = _inMemoryStore[requestId];
            if (req4 == null || !req4.status.isActive) return;

            final now4 = DateTime.now();
            final updated4 = req4.copyWith(
              status: RequestStatus.arrivedAtPatient,
              t6AmbulanceArrived: now4,
            ) as EmergencyRequestModel;
            _updateAndEmit(updated4);

            // 5. Arrived -> Patient Onboard
            _schedule(baseDelay, () {
              final req5 = _inMemoryStore[requestId];
              if (req5 == null || !req5.status.isActive) return;

              final updated5 = req5.copyWith(
                status: RequestStatus.patientOnboard,
                hospitalDestination: 'Apollo Speciality Hospital, Chennai',
              ) as EmergencyRequestModel;
              _updateAndEmit(updated5);

              // 6. Patient Onboard -> Completed
              _schedule(baseDelay, () {
                final req6 = _inMemoryStore[requestId];
                if (req6 == null || !req6.status.isActive) return;

                final updated6 = req6.copyWith(
                  status: RequestStatus.completed,
                ) as EmergencyRequestModel;
                _updateAndEmit(updated6);
              });
            });
          });
        });
      });
    });
  }

  void _runDriverRejectionScenario(String requestId, Duration baseDelay) {
    // 1. Searching -> Assigned Ambulance 1
    _schedule(baseDelay, () {
      final req = _inMemoryStore[requestId];
      if (req == null || !req.status.isActive) return;

      final updated = req.copyWith(
        status: RequestStatus.assigned,
        assignedAmbulanceId: 'AMB-CH-011',
        assignedDriverName: 'Suresh Kumar',
        driverPhone: '+91 94440 11111',
      ) as EmergencyRequestModel;
      _updateAndEmit(updated);

      // 2. Driver 1 Rejects -> Fallback Triggered (Request remains active!)
      _schedule(baseDelay, () {
        final req2 = _inMemoryStore[requestId];
        if (req2 == null || !req2.status.isActive) return;

        final updated2 = req2.copyWith(
          status: RequestStatus.searching, // Re-enters searching with fallback count
          fallbackCount: req2.fallbackCount + 1,
          assignedAmbulanceId: null,
          assignedDriverName: null,
        ) as EmergencyRequestModel;
        _updateAndEmit(updated2);

        // 3. Fallback Dispatch -> Assigned Ambulance 2
        _schedule(baseDelay * 1.2, () {
          final req3 = _inMemoryStore[requestId];
          if (req3 == null || !req3.status.isActive) return;

          final updated3 = req3.copyWith(
            status: RequestStatus.assigned,
            assignedAmbulanceId: 'AMB-CH-089',
            assignedDriverName: 'Manojbabu P.',
            driverPhone: '+91 97890 55555',
          ) as EmergencyRequestModel;
          _updateAndEmit(updated3);

          // 4. Driver 2 Accepts -> En Route
          _schedule(baseDelay, () {
            final req4 = _inMemoryStore[requestId];
            if (req4 == null || !req4.status.isActive) return;

            final updated4 = req4.copyWith(
              status: RequestStatus.accepted,
            ) as EmergencyRequestModel;
            _updateAndEmit(updated4);
          });
        });
      });
    });
  }

  void _runDriverTimeoutScenario(String requestId, Duration baseDelay) {
    _schedule(baseDelay, () {
      final req = _inMemoryStore[requestId];
      if (req == null || !req.status.isActive) return;

      // Assign initial ambulance
      final updated = req.copyWith(
        status: RequestStatus.assigned,
        assignedAmbulanceId: 'AMB-CH-033',
        assignedDriverName: 'Dinesh V.',
      ) as EmergencyRequestModel;
      _updateAndEmit(updated);

      // Timeout expires with no response -> Trigger cascading fallback
      _schedule(baseDelay * 1.5, () {
        final req2 = _inMemoryStore[requestId];
        if (req2 == null || !req2.status.isActive) return;

        final updated2 = req2.copyWith(
          status: RequestStatus.searching,
          fallbackCount: req2.fallbackCount + 1,
          assignedAmbulanceId: null,
          assignedDriverName: null,
        ) as EmergencyRequestModel;
        _updateAndEmit(updated2);

        // Reassign secondary vehicle
        _schedule(baseDelay, () {
          final req3 = _inMemoryStore[requestId];
          if (req3 == null || !req3.status.isActive) return;

          final updated3 = req3.copyWith(
            status: RequestStatus.accepted,
            assignedAmbulanceId: 'AMB-CH-099',
            assignedDriverName: 'Vikramaditya S.',
            driverPhone: '+91 91234 56789',
          ) as EmergencyRequestModel;
          _updateAndEmit(updated3);
        });
      });
    });
  }

  void _runNoAmbulanceScenario(String requestId, Duration baseDelay) {
    _schedule(baseDelay * 1.5, () {
      final req = _inMemoryStore[requestId];
      if (req == null || !req.status.isActive) return;

      final updated = req.copyWith(
        status: RequestStatus.noAmbulanceAvailable,
      ) as EmergencyRequestModel;
      _updateAndEmit(updated);
    });
  }

  void _schedule(Duration delay, void Function() action) {
    final timer = Timer(delay, action);
    _activeTimers.add(timer);
  }

  void _updateAndEmit(EmergencyRequestModel updated) {
    _inMemoryStore[updated.requestId] = updated;
    if (_streamControllers.containsKey(updated.requestId)) {
      final controller = _streamControllers[updated.requestId]!;
      if (!controller.isClosed) {
        controller.add(updated);
      }
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
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}
