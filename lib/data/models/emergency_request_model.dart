import '../../domain/entities/emergency_request.dart';
import '../../domain/entities/emergency_type.dart';
import '../../domain/entities/location_data.dart';
import '../../domain/entities/request_status.dart';
import 'location_model.dart';

/// Data model for EmergencyRequest with JSON serialization adhering to the REST API contract.
class EmergencyRequestModel extends EmergencyRequest {
  const EmergencyRequestModel({
    required super.requestId,
    required super.requesterId,
    required super.emergencyType,
    required super.victimCount,
    required super.emergencyLocation,
    super.requesterLocation,
    required super.createdAt,
    required super.status,
    super.assignedAmbulanceId,
    super.assignedDriverName,
    super.driverPhone,
    super.hospitalDestination,
    super.additionalNotes,
    super.fallbackCount,
    super.t0UserPressed,
    super.t1RequestReceived,
    super.t2MatchingCompleted,
    super.t3AssignmentSent,
    super.t4DriverAccepted,
    super.t5AmbulanceStarted,
    super.t6AmbulanceArrived,
  });

  factory EmergencyRequestModel.fromJson(Map<String, dynamic> json) {
    // Accommodate nested or flat location representations from backend
    final LocationData emergencyLoc;
    if (json['emergencyLocation'] != null) {
      emergencyLoc = LocationModel.fromJson(json['emergencyLocation'] as Map<String, dynamic>);
    } else {
      emergencyLoc = LocationData(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['locationAccuracy'] as num?)?.toDouble(),
        timestamp: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isManualOverride: json['isManualOverride'] as bool? ?? false,
      );
    }

    LocationData? requesterLoc;
    if (json['requesterLocation'] != null) {
      requesterLoc = LocationModel.fromJson(json['requesterLocation'] as Map<String, dynamic>);
    }

    return EmergencyRequestModel(
      requestId: json['requestId'] as String? ?? 'UK-${DateTime.now().millisecondsSinceEpoch}',
      requesterId: json['requesterId'] as String? ?? 'anonymous',
      emergencyType: EmergencyType.fromCode(json['emergencyType'] as String? ?? 'OTHER'),
      victimCount: json['victimCount'] as int? ?? 1,
      emergencyLocation: emergencyLoc,
      requesterLocation: requesterLoc,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      status: RequestStatus.fromCode(json['status'] as String? ?? 'CREATED'),
      assignedAmbulanceId: json['assignedAmbulanceId'] as String?,
      assignedDriverName: json['assignedDriverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      hospitalDestination: json['hospitalDestination'] as String?,
      additionalNotes: json['additionalNotes'] as String?,
      fallbackCount: json['fallbackCount'] as int? ?? 0,
      t0UserPressed: json['t0UserPressed'] != null ? DateTime.parse(json['t0UserPressed'] as String) : null,
      t1RequestReceived: json['t1RequestReceived'] != null ? DateTime.parse(json['t1RequestReceived'] as String) : null,
      t2MatchingCompleted: json['t2MatchingCompleted'] != null ? DateTime.parse(json['t2MatchingCompleted'] as String) : null,
      t3AssignmentSent: json['t3AssignmentSent'] != null ? DateTime.parse(json['t3AssignmentSent'] as String) : null,
      t4DriverAccepted: json['t4DriverAccepted'] != null ? DateTime.parse(json['t4DriverAccepted'] as String) : null,
      t5AmbulanceStarted: json['t5AmbulanceStarted'] != null ? DateTime.parse(json['t5AmbulanceStarted'] as String) : null,
      t6AmbulanceArrived: json['t6AmbulanceArrived'] != null ? DateTime.parse(json['t6AmbulanceArrived'] as String) : null,
    );
  }

  factory EmergencyRequestModel.fromEntity(EmergencyRequest entity) {
    return EmergencyRequestModel(
      requestId: entity.requestId,
      requesterId: entity.requesterId,
      emergencyType: entity.emergencyType,
      victimCount: entity.victimCount,
      emergencyLocation: entity.emergencyLocation,
      requesterLocation: entity.requesterLocation,
      createdAt: entity.createdAt,
      status: entity.status,
      assignedAmbulanceId: entity.assignedAmbulanceId,
      assignedDriverName: entity.assignedDriverName,
      driverPhone: entity.driverPhone,
      hospitalDestination: entity.hospitalDestination,
      additionalNotes: entity.additionalNotes,
      fallbackCount: entity.fallbackCount,
      t0UserPressed: entity.t0UserPressed,
      t1RequestReceived: entity.t1RequestReceived,
      t2MatchingCompleted: entity.t2MatchingCompleted,
      t3AssignmentSent: entity.t3AssignmentSent,
      t4DriverAccepted: entity.t4DriverAccepted,
      t5AmbulanceStarted: entity.t5AmbulanceStarted,
      t6AmbulanceArrived: entity.t6AmbulanceArrived,
    );
  }

  @override
  EmergencyRequestModel copyWith({
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
    return EmergencyRequestModel(
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

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'requesterId': requesterId,
      'emergencyType': emergencyType.code,
      'victimCount': victimCount,
      'latitude': emergencyLocation.latitude,
      'longitude': emergencyLocation.longitude,
      'locationAccuracy': emergencyLocation.accuracy,
      'isManualOverride': emergencyLocation.isManualOverride,
      'createdAt': createdAt.toIso8601String(),
      'status': status.code,
      if (assignedAmbulanceId != null) 'assignedAmbulanceId': assignedAmbulanceId,
      if (assignedDriverName != null) 'assignedDriverName': assignedDriverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      if (hospitalDestination != null) 'hospitalDestination': hospitalDestination,
      if (additionalNotes != null) 'additionalNotes': additionalNotes,
      'fallbackCount': fallbackCount,
      if (t0UserPressed != null) 't0UserPressed': t0UserPressed!.toIso8601String(),
      if (t1RequestReceived != null) 't1RequestReceived': t1RequestReceived!.toIso8601String(),
      if (t2MatchingCompleted != null) 't2MatchingCompleted': t2MatchingCompleted!.toIso8601String(),
      if (t3AssignmentSent != null) 't3AssignmentSent': t3AssignmentSent!.toIso8601String(),
      if (t4DriverAccepted != null) 't4DriverAccepted': t4DriverAccepted!.toIso8601String(),
      if (t5AmbulanceStarted != null) 't5AmbulanceStarted': t5AmbulanceStarted!.toIso8601String(),
      if (t6AmbulanceArrived != null) 't6AmbulanceArrived': t6AmbulanceArrived!.toIso8601String(),
    };
  }

  /// Format specifically for POST /api/emergency-requests endpoint.
  Map<String, dynamic> toSubmissionJson() {
    return {
      'requesterId': requesterId,
      'emergencyType': emergencyType.code,
      'victimCount': victimCount,
      'latitude': emergencyLocation.latitude,
      'longitude': emergencyLocation.longitude,
      'locationAccuracy': emergencyLocation.accuracy,
      'isManualOverride': emergencyLocation.isManualOverride,
      if (additionalNotes != null && additionalNotes!.isNotEmpty)
        'additionalNotes': additionalNotes,
      if (t0UserPressed != null) 't0UserPressed': t0UserPressed!.toIso8601String(),
    };
  }
}
