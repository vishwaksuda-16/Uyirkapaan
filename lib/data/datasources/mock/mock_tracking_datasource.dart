import 'dart:async';
import '../../models/eta_model.dart';
import '../../models/tracking_model.dart';
import '../../../domain/entities/request_status.dart';
import '../tracking_datasource.dart';

/// Simulated Tracking DataSource for demonstrating real-time UI placeholders.
/// Does NOT run real Dijkstra, traffic simulation, or Distance Matrix calculations.
class MockTrackingDataSource implements TrackingDataSource {
  final Map<String, StreamController<TrackingModel>> _trackingControllers = {};
  final Map<String, StreamController<EtaModel>> _etaControllers = {};
  final List<Timer> _activeTimers = [];

  @override
  Future<TrackingModel?> getTrackingInfo(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return TrackingModel(
      ambulanceId: 'AMB-CH-042',
      requestId: requestId,
      latitude: 13.0850,
      longitude: 80.2730,
      speedKmH: 45.5,
      headingDegrees: 180.0,
      timestamp: DateTime.now(),
      status: RequestStatus.enRouteToPatient,
      eta: EtaModel(
        estimatedMinutes: 6,
        distanceMeters: 2400.0,
        lastCalculatedAt: DateTime.now(),
        trafficCondition: 'Moderate Traffic',
      ),
      vehicleNumber: 'TN-01-EM-1081',
      driverName: 'Karthik Raja',
      driverPhone: '+91 98401 23456',
    );
  }

  @override
  Future<EtaModel?> getEta(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return EtaModel(
      estimatedMinutes: 6,
      distanceMeters: 2400.0,
      lastCalculatedAt: DateTime.now(),
      trafficCondition: 'Moderate Traffic',
    );
  }

  @override
  Stream<TrackingModel> watchTrackingUpdates(String requestId) {
    if (!_trackingControllers.containsKey(requestId)) {
      _trackingControllers[requestId] = StreamController<TrackingModel>.broadcast();
      _startSimulatedTelemetryStream(requestId);
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

  void _startSimulatedTelemetryStream(String requestId) {
    int currentEta = 8;
    double currentLat = 13.0900;
    double currentLng = 80.2780;

    final timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!_trackingControllers.containsKey(requestId) ||
          _trackingControllers[requestId]!.isClosed) {
        t.cancel();
        return;
      }

      currentEta = (currentEta > 1) ? currentEta - 1 : 1;
      currentLat -= 0.0012;
      currentLng -= 0.0010;

      final eta = EtaModel(
        estimatedMinutes: currentEta,
        distanceMeters: currentEta * 400.0,
        lastCalculatedAt: DateTime.now(),
        trafficCondition: 'Green Corridor Active',
      );

      final tracking = TrackingModel(
        ambulanceId: 'AMB-CH-042',
        requestId: requestId,
        latitude: currentLat,
        longitude: currentLng,
        speedKmH: 52.0,
        headingDegrees: 225.0,
        timestamp: DateTime.now(),
        status: RequestStatus.enRouteToPatient,
        eta: eta,
        vehicleNumber: 'TN-01-EM-1081',
        driverName: 'Karthik Raja',
        driverPhone: '+91 98401 23456',
      );

      _trackingControllers[requestId]!.add(tracking);

      if (_etaControllers.containsKey(requestId) && !_etaControllers[requestId]!.isClosed) {
        _etaControllers[requestId]!.add(eta);
      }
    });

    _activeTimers.add(timer);
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
  }
}
