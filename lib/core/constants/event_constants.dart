/// Centralized Real-Time WebSocket / SSE Event Names.
/// Adheres strictly to the integration contract for Module 6 (Tracking & Real-time Layer).
class EventConstants {
  EventConstants._();

  // Inbound real-time events consumed by Bystander App
  static const String ambulanceAssigned = 'AMBULANCE_ASSIGNED';
  static const String driverAccepted = 'DRIVER_ACCEPTED';
  static const String driverRejected = 'DRIVER_REJECTED';
  static const String fallbackTriggered = 'FALLBACK_TRIGGERED';
  static const String locationUpdated = 'LOCATION_UPDATED';
  static const String etaUpdated = 'ETA_UPDATED';
  static const String ambulanceArrived = 'AMBULANCE_ARRIVED';
  static const String patientOnboard = 'PATIENT_ONBOARD';
  static const String hospitalArrival = 'HOSPITAL_ARRIVAL';
  static const String requestCompleted = 'REQUEST_COMPLETED';
  static const String noAmbulanceAvailable = 'NO_AMBULANCE_AVAILABLE';
  static const String requestCancelled = 'REQUEST_CANCELLED';

  // Outbound client events/actions
  static const String joinRequestRoom = 'JOIN_REQUEST_ROOM';
  static const String leaveRequestRoom = 'LEAVE_REQUEST_ROOM';
}
