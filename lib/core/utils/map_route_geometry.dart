import 'dart:math' as math;
import '../../domain/entities/location_data.dart';

/// Builds street-like polyline paths between two points for realistic emergency routing.
class MapRouteGeometry {
  MapRouteGeometry._();

  /// Builds realistic multi-segment urban road waypoints from [from] to [to].
  static List<LocationData> buildSimulatedRoute({
    required LocationData from,
    required LocationData to,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    final deltaLat = to.latitude - from.latitude;
    final deltaLng = to.longitude - from.longitude;

    // Follow urban street grid (avenue and cross-street axes) rather than diagonal building cuts
    return [
      from.copyWith(timestamp: now),
      LocationData(
        latitude: from.latitude + deltaLat * 0.40,
        longitude: from.longitude,
        timestamp: now,
      ),
      LocationData(
        latitude: from.latitude + deltaLat * 0.40,
        longitude: from.longitude + deltaLng * 0.70,
        timestamp: now,
      ),
      LocationData(
        latitude: from.latitude + deltaLat * 0.85,
        longitude: from.longitude + deltaLng * 0.70,
        timestamp: now,
      ),
      LocationData(
        latitude: from.latitude + deltaLat * 0.85,
        longitude: to.longitude,
        timestamp: now,
      ),
      to.copyWith(timestamp: now),
    ];
  }

  /// Interpolates a route of [waypoints] into [totalSteps] finely spaced steps
  /// for smooth, vehicular movement along road corridors without teleporting.
  static List<LocationData> interpolatePath(
    List<LocationData> waypoints, {
    int totalSteps = 24,
  }) {
    if (waypoints.isEmpty) return [];
    if (waypoints.length == 1) return [waypoints.first];
    if (waypoints.length >= totalSteps && waypoints.length <= totalSteps * 2) {
      return waypoints;
    }

    final List<LocationData> result = [];
    final int segments = waypoints.length - 1;
    final int stepsPerSegment = math.max(1, (totalSteps / segments).ceil());

    for (int i = 0; i < segments; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];

      for (int s = 0; s < stepsPerSegment; s++) {
        final t = s / stepsPerSegment;
        final lat = start.latitude + (end.latitude - start.latitude) * t;
        final lng = start.longitude + (end.longitude - start.longitude) * t;
        result.add(
          LocationData(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    result.add(waypoints.last);
    return result;
  }

  /// Resamples any polyline path (e.g. from OSRM driving routes or simulated grids)
  /// into exactly [targetSteps] equidistant steps along the cumulative distance.
  /// Guarantees that index 0 is [waypoints.first] and index [targetSteps] is [waypoints.last].
  static List<LocationData> resamplePath(
    List<LocationData> waypoints, {
    int targetSteps = 10,
  }) {
    if (waypoints.isEmpty) return [];
    if (waypoints.length == 1) return [waypoints.first];
    if (targetSteps <= 0) return [waypoints.first, waypoints.last];

    // Compute segment lengths
    final List<double> segmentLengths = [];
    double totalDistance = 0.0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      final latRad = (a.latitude + b.latitude) / 2.0 * (math.pi / 180.0);
      final dLat = b.latitude - a.latitude;
      final dLng = (b.longitude - a.longitude) * math.cos(latRad);
      final dist = math.sqrt(dLat * dLat + dLng * dLng);
      segmentLengths.add(dist);
      totalDistance += dist;
    }

    if (totalDistance == 0.0) {
      return List.filled(targetSteps + 1, waypoints.first);
    }

    final List<LocationData> resampled = [waypoints.first];
    final double stepDist = totalDistance / targetSteps;

    int segIdx = 0;
    double distIntoSeg = 0.0;

    for (int step = 1; step < targetSteps; step++) {
      final targetDist = step * stepDist;

      // Advance through segments until targetDist is reached
      double accumulated = 0.0;
      for (int i = 0; i < segmentLengths.length; i++) {
        if (accumulated + segmentLengths[i] >= targetDist) {
          segIdx = i;
          distIntoSeg = targetDist - accumulated;
          break;
        }
        accumulated += segmentLengths[i];
      }

      final segLen = segmentLengths[segIdx];
      final t = segLen > 0 ? distIntoSeg / segLen : 0.0;
      final a = waypoints[segIdx];
      final b = waypoints[segIdx + 1];

      resampled.add(
        LocationData(
          latitude: a.latitude + (b.latitude - a.latitude) * t,
          longitude: a.longitude + (b.longitude - a.longitude) * t,
          timestamp: DateTime.now(),
        ),
      );
    }

    resampled.add(waypoints.last);
    return resampled;
  }

  /// Computes compass heading angle in degrees (0 - 360) from [from] to [to].
  /// Returns [fallbackHeading] if the distance between points is negligible.
  static double headingDegrees(LocationData from, LocationData to, [double? fallbackHeading]) {
    final dLng = to.longitude - from.longitude;
    final dLat = to.latitude - from.latitude;
    if (dLng.abs() < 1e-6 && dLat.abs() < 1e-6) {
      return fallbackHeading ?? from.heading ?? 0.0;
    }
    final degrees = math.atan2(dLng, dLat) * (180 / math.pi);
    return (degrees + 360) % 360;
  }

  /// Calculates the exact coordinate snapped along the route segments of [path]
  /// at a normalized progress fraction [t] in [0.0, 1.0].
  static LocationData getPointAtProgress(
    List<LocationData> path,
    double t, {
    double? fallbackHeading,
  }) {
    if (path.isEmpty) {
      return LocationData(latitude: 0, longitude: 0, timestamp: DateTime.now());
    }
    if (path.length == 1 || t <= 0.0) {
      return path.first;
    }
    if (t >= 1.0) {
      return path.last;
    }

    // Compute segment lengths
    final List<double> segLens = [];
    double totalDist = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final latRad = (a.latitude + b.latitude) / 2.0 * (math.pi / 180.0);
      final dLat = b.latitude - a.latitude;
      final dLng = (b.longitude - a.longitude) * math.cos(latRad);
      final dist = math.sqrt(dLat * dLat + dLng * dLng);
      segLens.add(dist);
      totalDist += dist;
    }

    if (totalDist <= 0.0) {
      return path.first;
    }

    final targetDist = t * totalDist;
    double accum = 0.0;
    int segIdx = 0;
    double distIntoSeg = 0.0;

    for (int i = 0; i < segLens.length; i++) {
      if (accum + segLens[i] >= targetDist) {
        segIdx = i;
        distIntoSeg = targetDist - accum;
        break;
      }
      accum += segLens[i];
    }

    final segLen = segLens[segIdx];
    final segFrac = segLen > 0 ? (distIntoSeg / segLen).clamp(0.0, 1.0) : 0.0;
    final p1 = path[segIdx];
    final p2 = path[segIdx + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * segFrac;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * segFrac;
    final heading = headingDegrees(p1, p2, fallbackHeading);

    return LocationData(
      latitude: lat,
      longitude: lng,
      heading: heading,
      timestamp: DateTime.now(),
    );
  }
}

