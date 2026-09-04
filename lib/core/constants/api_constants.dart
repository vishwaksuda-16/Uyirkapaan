/// Centralized API endpoint routes and configuration.
/// Ensures the application adheres strictly to the backend integration contract.
class ApiConstants {
  ApiConstants._();

  /// Base URL can be injected via environment or configuration.
  static const String defaultBaseUrl = 'https://api.uyirkappan.local/v1';

  // REST API Endpoints
  static const String emergencyRequests = '/api/emergency-requests';
  static String emergencyRequestById(String id) => '/api/emergency-requests/$id';
  static String emergencyRequestStatus(String id) => '/api/emergency-requests/$id/status';
  static String cancelEmergencyRequest(String id) => '/api/emergency-requests/$id/cancel';
  static String assignedAmbulance(String id) => '/api/emergency-requests/$id/ambulance';
  static String trackingInfo(String id) => '/api/emergency-requests/$id/tracking';

  // Request Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';
  static const String contentTypeJson = 'application/json';
}
