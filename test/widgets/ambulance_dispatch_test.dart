import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyirkappan_bystander/data/datasources/adaptive/adaptive_datasources.dart';
import 'package:uyirkappan_bystander/data/datasources/mock/mock_emergency_request_datasource.dart';
import 'package:uyirkappan_bystander/data/datasources/mock/mock_tracking_datasource.dart';
import 'package:uyirkappan_bystander/data/repositories/emergency_request_repository_impl.dart';
import 'package:uyirkappan_bystander/data/repositories/tracking_repository_impl.dart';
import 'package:uyirkappan_bystander/domain/entities/emergency_request.dart';
import 'package:uyirkappan_bystander/domain/entities/request_status.dart';
import 'package:uyirkappan_bystander/presentation/controllers/emergency_controller.dart';
import 'package:uyirkappan_bystander/presentation/controllers/location_controller.dart';
import 'package:uyirkappan_bystander/presentation/screens/home/home_screen.dart';
import 'package:uyirkappan_bystander/presentation/widgets/map/openfreemap_view.dart';
import '../unit/mock_repository_test.dart';

void main() {
  testWidgets('clicking REQUEST AMBULANCE passes ambulanceLocation and route to OpenFreeMapView', (tester) async {
    final mockTracking = MockTrackingDataSource();
    final mockRequest = MockEmergencyRequestDataSource(trackingDataSource: mockTracking);
    final fakeLocal = FakeLocalDataSource();
    final emergencyRepo = EmergencyRequestRepositoryImpl(dataSource: mockRequest, localDataSource: fakeLocal);
    final adaptiveTracking = AdaptiveTrackingDataSource(mockDataSource: mockTracking, useRemoteNotifier: ValueNotifier(false));
    final trackingRepo = TrackingRepositoryImpl(dataSource: adaptiveTracking);

    final emergencyController = EmergencyController(repository: emergencyRepo);
    final locationController = LocationController();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          emergencyController: emergencyController,
          locationController: locationController,
          trackingRepository: trackingRepo,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify initial idle state
    final initialMap = tester.widget<OpenFreeMapView>(find.byType(OpenFreeMapView));
    expect(initialMap.ambulanceLocation, isNull);
    expect(initialMap.routeWaypoints, isNull);

    // Tap REQUEST AMBULANCE
    await tester.tap(find.text('REQUEST AMBULANCE'));
    await tester.pump();

    // Fast forward 1500ms so Stage 1 (assigned) fires
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));

    // Check OpenFreeMapView now
    final assignedMap = tester.widget<OpenFreeMapView>(find.byType(OpenFreeMapView));
    expect(assignedMap.ambulanceLocation, isNotNull);
    expect(assignedMap.routeWaypoints, isNotNull);
    expect(assignedMap.routeWaypoints!.isNotEmpty, isTrue);

    // Pump past Stage 2 timer (1200ms)
    await tester.pump(const Duration(milliseconds: 1300));

    mockRequest.dispose();
    mockTracking.clearAll();
  });

  testWidgets('ambulance automatically progresses to arrivedAtPatient and enRouteToHospital', (tester) async {
    final mockTracking = MockTrackingDataSource();
    final mockRequest = MockEmergencyRequestDataSource(trackingDataSource: mockTracking);
    final fakeLocal = FakeLocalDataSource();
    final emergencyRepo = EmergencyRequestRepositoryImpl(dataSource: mockRequest, localDataSource: fakeLocal);
    final adaptiveTracking = AdaptiveTrackingDataSource(mockDataSource: mockTracking, useRemoteNotifier: ValueNotifier(false));
    final trackingRepo = TrackingRepositoryImpl(dataSource: adaptiveTracking);

    final emergencyController = EmergencyController(repository: emergencyRepo);
    final locationController = LocationController();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          emergencyController: emergencyController,
          locationController: locationController,
          trackingRepository: trackingRepo,
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('REQUEST AMBULANCE'));
    await tester.pump();

    // Stage 1 & 2: Assigned & En Route
    await tester.pump(const Duration(milliseconds: 2500));

    // Fast forward through ticks (14 ticks * 750ms = 10.5s) so ambulance drives to scene
    for (int i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 800));
    }

    // Ambulance has arrived at scene and transitioned to hospital transit
    final finalStatus = emergencyController.activeRequest?.status;
    expect(
      finalStatus == RequestStatus.arrivedAtPatient ||
          finalStatus == RequestStatus.patientOnboard ||
          finalStatus == RequestStatus.enRouteToHospital,
      isTrue,
    );

    // Fast forward to hospital transit phase
    await tester.pump(const Duration(seconds: 6));
    expect(emergencyController.activeRequest?.status.code, 'EN_ROUTE_TO_HOSPITAL');

    // Verify map is given the hospital route
    final hospitalMap = tester.widget<OpenFreeMapView>(find.byType(OpenFreeMapView));
    expect(hospitalMap.routeWaypoints, isNotNull);
    expect(hospitalMap.routeWaypoints!.isNotEmpty, isTrue);

    mockRequest.dispose();
    mockTracking.clearAll();
  });
}
