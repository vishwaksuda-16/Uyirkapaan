import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/emergency_request_model.dart';
import '../../../domain/entities/request_status.dart';
import '../emergency_request_datasource.dart';

/// Real REST API implementation adhering strictly to the backend integration contract.
class RemoteEmergencyRequestDataSource implements EmergencyRequestDataSource {
  final http.Client client;
  final String baseUrl;

  RemoteEmergencyRequestDataSource({
    required this.client,
    this.baseUrl = ApiConstants.defaultBaseUrl,
  });

  @override
  Future<EmergencyRequestModel> createEmergencyRequest(EmergencyRequestModel request) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.emergencyRequests}');
    try {
      final response = await client.post(
        uri,
        headers: {
          ApiConstants.headerContentType: ApiConstants.contentTypeJson,
        },
        body: jsonEncode(request.toSubmissionJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        return EmergencyRequestModel.fromJson(body);
      } else {
        throw ServerException(
          'Failed to submit emergency request: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Network error during request submission: $e');
    }
  }

  @override
  Future<EmergencyRequestModel> getEmergencyRequest(String requestId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.emergencyRequestById(requestId)}');
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        return EmergencyRequestModel.fromJson(body);
      } else {
        throw ServerException(
          'Failed to fetch emergency request: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Network error fetching request: $e');
    }
  }

  @override
  Future<RequestStatus> getRequestStatus(String requestId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.emergencyRequestStatus(requestId)}');
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        final statusCode = body['status'] as String? ?? 'SEARCHING';
        return RequestStatus.fromCode(statusCode);
      } else {
        throw ServerException('Failed to get status', response.statusCode);
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Network error fetching status: $e');
    }
  }

  @override
  Future<EmergencyRequestModel> cancelEmergencyRequest(String requestId, {String? reason}) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.cancelEmergencyRequest(requestId)}');
    try {
      final response = await client.post(
        uri,
        headers: {ApiConstants.headerContentType: ApiConstants.contentTypeJson},
        body: jsonEncode({'reason': reason ?? 'Cancelled by user'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        return EmergencyRequestModel.fromJson(body);
      } else {
        throw ServerException('Failed to cancel request', response.statusCode);
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Network error during cancellation: $e');
    }
  }

  @override
  Stream<EmergencyRequestModel> watchRequestUpdates(String requestId) {
    // In production, this can connect to WebSocket / Server-Sent Events.
    // For REST fallback, polling stream can be used.
    final controller = StreamController<EmergencyRequestModel>.broadcast();
    Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      try {
        final req = await getEmergencyRequest(requestId);
        controller.add(req);
        if (!req.status.isActive) {
          timer.cancel();
        }
      } catch (_) {
        // Keep stream open on temporary network blips
      }
    });
    return controller.stream;
  }
}
