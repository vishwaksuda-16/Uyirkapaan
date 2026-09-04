import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/eta_model.dart';
import '../../models/tracking_model.dart';
import '../tracking_datasource.dart';

/// Real REST/WebSocket Data Source for ambulance tracking integration with Module 6.
class RemoteTrackingDataSource implements TrackingDataSource {
  final http.Client client;
  final String baseUrl;

  RemoteTrackingDataSource({
    required this.client,
    this.baseUrl = ApiConstants.defaultBaseUrl,
  });

  @override
  Future<TrackingModel?> getTrackingInfo(String requestId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.trackingInfo(requestId)}');
    try {
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        return TrackingModel.fromJson(body);
      }
      return null;
    } catch (e) {
      throw NetworkException('Failed to retrieve tracking info: $e');
    }
  }

  @override
  Future<EtaModel?> getEta(String requestId) async {
    final tracking = await getTrackingInfo(requestId);
    return tracking?.eta as EtaModel?;
  }

  @override
  Stream<TrackingModel> watchTrackingUpdates(String requestId) {
    // Module 6 will hook up WebSocket / Socket.IO here.
    // Placeholder stream provided for current interface compatibility.
    final controller = StreamController<TrackingModel>.broadcast();
    return controller.stream;
  }

  @override
  Stream<EtaModel> watchEtaUpdates(String requestId) {
    final controller = StreamController<EtaModel>.broadcast();
    return controller.stream;
  }
}
