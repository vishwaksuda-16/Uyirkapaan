import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyirkappan_bystander/core/constants/map_constants.dart';
import 'package:uyirkappan_bystander/domain/entities/location_data.dart';
import 'package:uyirkappan_bystander/presentation/widgets/map/map_style_selector.dart';
import 'package:uyirkappan_bystander/presentation/widgets/map/openfreemap_view.dart';

void main() {
  group('OpenFreeMapView & MapStyleSelector Tests', () {
    testWidgets('should render OpenFreeMapView with default incident pinpoint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenFreeMapView(
              incidentLocation: LocationData(
                latitude: 13.0827,
                longitude: 80.2707,
                timestamp: DateTime.now(),
              ),
              style: OpenFreeMapStyle.bright,
              isPickerMode: false,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('INCIDENT'), findsOneWidget);
      expect(find.textContaining('OpenFreeMap'), findsOneWidget);
    });

    testWidgets('should render userLocation and incidentLocation markers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpenFreeMapView(
              userLocation: LocationData(
                latitude: 13.0800,
                longitude: 80.2700,
                timestamp: DateTime.now(),
              ),
              incidentLocation: LocationData(
                latitude: 13.0827,
                longitude: 80.2707,
                timestamp: DateTime.now(),
              ),
              style: OpenFreeMapStyle.bright,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('INCIDENT'), findsOneWidget);
    });

    testWidgets('should trigger onLocationPicked when tapped in picker mode', (tester) async {
      LocationData? pickedLocation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: OpenFreeMapView(
                incidentLocation: LocationData(
                  latitude: 13.0827,
                  longitude: 80.2707,
                  timestamp: DateTime.now(),
                ),
                style: OpenFreeMapStyle.bright,
                isPickerMode: true,
                onLocationPicked: (loc) {
                  pickedLocation = loc;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('PICKUP POINT'), findsOneWidget);

      // Tap on map area offset from center
      await tester.tapAt(const Offset(300, 400));
      await tester.pump(const Duration(milliseconds: 500));

      expect(pickedLocation, isNotNull);
      expect(pickedLocation!.isManualOverride, isTrue);
    });

    testWidgets('should render MapStyleSelector and allow switching styles', (tester) async {
      OpenFreeMapStyle activeStyle = OpenFreeMapStyle.bright;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: MapStyleSelector(
                  currentStyle: activeStyle,
                  onStyleSelected: (style) {
                    setState(() {
                      activeStyle = style;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();

      expect(find.text('Bright'), findsOneWidget);
      expect(find.text('Liberty'), findsOneWidget);
      expect(find.text('Positron'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Fiord'), findsOneWidget);
      expect(find.text('3D Buildings'), findsOneWidget);

      // Switch to Dark style
      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(activeStyle, OpenFreeMapStyle.dark);
    });
  });
}
