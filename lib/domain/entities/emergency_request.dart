import 'emergency_type.dart';
import 'location_data.dart';
import 'request_status.dart';

/// Core business entity representing an emergency incident request.
class EmergencyRequest {
  final String requestId;
  final String requesterId;
  final EmergencyType emergencyType;
  final int victimCount;
  final LocationData emergencyLocation;
  final LocationData? requesterLocation;
  final DateTime createdAt;
  final RequestStatus status;
  final String? assignedAmbulanceId;
  final String? assignedDriverName;
  final String? driverPhone;
  final String? hospitalDestination;
  final String? additionalNotes;
  final int fallbackCount;

  // Evaluation Timestamps (for response-time analytics: T0 - T6)
  final DateTime? t0UserPressed;
  final DateTime? t1RequestReceived;
  final DateTime? t2MatchingCompleted;
  final DateTime? t3AssignmentSent;
  final DateTime? t4DriverAccepted;
  final DateTime? t5AmbulanceStarted;
  final DateTime? t6AmbulanceArrived;

  const EmergencyRequest({
    required this.requestId,
    required this.requesterId,
    required this.emergencyType,
    required this.victimCount,
    required this.emergencyLocation,
    this.requesterLocation,
    required this.createdAt,
    required this.status,
    this.assignedAmbulanceId,
    this.assignedDriverName,
    this.driverPhone,
    this.hospitalDestination,
    this.additionalNotes,
    this.fallbackCount = 0,
    this.t0UserPressed,
    this.t1RequestReceived,
    this.t2MatchingCompleted,
    this.t3AssignmentSent,
    this.t4DriverAccepted,
    this.t5AmbulanceStarted,
    this.t6AmbulanceArrived,
  });

  EmergencyRequest copyWith({
    String? requestId,
    String? requesterId,
    EmergencyType? emergencyType,
    int? victimCount,
    LocationData? emergencyLocation,
    LocationData? requesterLocation,
    DateTime? createdAt,
    RequestStatus? status,
    String? assignedAmbulanceId,
    String? assignedDriverName,
    String? driverPhone,
    String? hospitalDestination,
    String? additionalNotes,
    int? fallbackCount,
    DateTime? t0UserPressed,
    DateTime? t1RequestReceived,
    DateTime? t2MatchingCompleted,
    DateTime? t3AssignmentSent,
    DateTime? t4DriverAccepted,
    DateTime? t5AmbulanceStarted,
    DateTime? t6AmbulanceArrived,
  }) {
    return EmergencyRequest(
      requestId: requestId ?? this.requestId,
      requesterId: requesterId ?? this.requesterId,
      emergencyType: emergencyType ?? this.emergencyType,
      victimCount: victimCount ?? this.victimCount,
      emergencyLocation: emergencyLocation ?? this.emergencyLocation,
      requesterLocation: requesterLocation ?? this.requesterLocation,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedAmbulanceId: assignedAmbulanceId ?? this.assignedAmbulanceId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      driverPhone: driverPhone ?? this.driverPhone,
      hospitalDestination: hospitalDestination ?? this.hospitalDestination,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      fallbackCount: fallbackCount ?? this.fallbackCount,
      t0UserPressed: t0UserPressed ?? this.t0UserPressed,
      t1RequestReceived: t1RequestReceived ?? this.t1RequestReceived,
      t2MatchingCompleted: t2MatchingCompleted ?? this.t2MatchingCompleted,
      t3AssignmentSent: t3AssignmentSent ?? this.t3AssignmentSent,
      t4DriverAccepted: t4DriverAccepted ?? this.t4DriverAccepted,
      t5AmbulanceStarted: t5AmbulanceStarted ?? this.t5AmbulanceStarted,
      t6AmbulanceArrived: t6AmbulanceArrived ?? this.t6AmbulanceArrived,
    );
  }

  // Response-time latency calculation helpers
  Duration? get dispatchLatency {
    if (t0UserPressed != null && t3AssignmentSent != null) {
      return t3AssignmentSent!.difference(t0UserPressed!);
    }
    return null;
  }

  Duration? get driverResponseTime {
    if (t3AssignmentSent != null && t4DriverAccepted != null) {
      return t4DriverAccepted!.difference(t3AssignmentSent!);
    }
    return null;
  }

  Duration? get travelTime {
    if (t5AmbulanceStarted != null && t6AmbulanceArrived != null) {
      return t6AmbulanceArrived!.difference(t5AmbulanceStarted!);
    }
    return null;
  }

  Duration? get totalResponseTime {
    if (t0UserPressed != null && t6AmbulanceArrived != null) {
      return t6AmbulanceArrived!.difference(t0UserPressed!);
    }
    return null;
  }
}
