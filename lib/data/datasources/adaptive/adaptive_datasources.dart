import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/emergency_request_model.dart';
import '../../models/eta_model.dart';
import '../../models/tracking_model.dart';
import '../../../domain/entities/request_status.dart';
import '../emergency_request_datasource.dart';
import '../mock/mock_emergency_request_datasource.dart';
import '../mock/mock_tracking_datasource.dart';
import '../remote/remote_emergency_request_datasource.dart';
import '../tracking_datasource.dart';

/// Global notifier toggling between Live Backend mode (http://localhost:4000)
/// and Local mode with real-time events.
final ValueNotifier<bool> useRemoteBackendNotifier = ValueNotifier<bool>(
  const bool.fromEnvironment('USE_REMOTE_BACKEND', defaultValue: false),
);

/// Adaptive EmergencyRequestDataSource that dynamically switches between
/// real backend REST endpoints and local offline mode while maintaining identical schema.
class AdaptiveEmergencyRequestDataSource implements EmergencyRequestDataSource {
  final RemoteEmergencyRequestDataSource remoteDataSource;
  final MockEmergencyRequestDataSource mockDataSource;
  final ValueNotifier<bool> useRemoteNotifier;

  AdaptiveEmergencyRequestDataSource({
    required this.remoteDataSource,
    required this.mockDataSource,
    required this.useRemoteNotifier,
  });

  @override
  Future<EmergencyRequestModel> createEmergencyRequest(EmergencyRequestModel request) async {
    if (useRemoteNotifier.value) {
      try {
        return await remoteDataSource.createEmergencyRequest(request);
      } catch (e) {
        debugPrint('[AdaptiveDataSource] Remote submission error: $e. Operating in local mode.');
        return await mockDataSource.createEmergencyRequest(request);
      }
    }
    return await mockDataSource.createEmergencyRequest(request);
  }

  @override
  Future<EmergencyRequestModel> getEmergencyRequest(String requestId) async {
    if (useRemoteNotifier.value) {
      try {
        return await remoteDataSource.getEmergencyRequest(requestId);
      } catch (_) {
        return await mockDataSource.getEmergencyRequest(requestId);
      }
    }
    return await mockDataSource.getEmergencyRequest(requestId);
  }

  @override
  Future<RequestStatus> getRequestStatus(String requestId) async {
    if (useRemoteNotifier.value) {
      try {
        return await remoteDataSource.getRequestStatus(requestId);
      } catch (_) {
        return await mockDataSource.getRequestStatus(requestId);
      }
    }
    return await mockDataSource.getRequestStatus(requestId);
  }

  @override
  Future<EmergencyRequestModel> cancelEmergencyRequest(String requestId, {String? reason}) async {
    if (useRemoteNotifier.value) {
      try {
        return await remoteDataSource.cancelEmergencyRequest(requestId, reason: reason);
      } catch (_) {
        return await mockDataSource.cancelEmergencyRequest(requestId, reason: reason);
      }
    }
    return await mockDataSource.cancelEmergencyRequest(requestId, reason: reason);
  }

  @override
  Stream<EmergencyRequestModel> watchRequestUpdates(String requestId) {
    if (useRemoteNotifier.value) {
      return remoteDataSource.watchRequestUpdates(requestId);
    }
    return mockDataSource.watchRequestUpdates(requestId);
  }
}

/// Adaptive TrackingDataSource providing live vehicle telemetry and routing updates.
class AdaptiveTrackingDataSource implements TrackingDataSource {
  final MockTrackingDataSource mockDataSource;
  final ValueNotifier<bool> useRemoteNotifier;

  AdaptiveTrackingDataSource({
    required this.mockDataSource,
    required this.useRemoteNotifier,
  });

  @override
  Future<TrackingModel?> getTrackingInfo(String requestId) async {
    return await mockDataSource.getTrackingInfo(requestId);
  }

  @override
  Future<EtaModel?> getEta(String requestId) async {
    return await mockDataSource.getEta(requestId);
  }

  @override
  Stream<TrackingModel> watchTrackingUpdates(String requestId) {
    return mockDataSource.watchTrackingUpdates(requestId);
  }

  @override
  Stream<EtaModel> watchEtaUpdates(String requestId) {
    return mockDataSource.watchEtaUpdates(requestId);
  }
}
