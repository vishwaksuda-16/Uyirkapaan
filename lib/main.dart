import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core/theme/app_theme.dart';
import 'data/datasources/local/request_local_datasource.dart';
import 'data/datasources/mock/mock_emergency_request_datasource.dart';
import 'data/datasources/mock/mock_tracking_datasource.dart';
import 'data/datasources/remote/remote_emergency_request_datasource.dart';
import 'data/datasources/remote/remote_tracking_datasource.dart';
import 'data/repositories/emergency_request_repository_impl.dart';
import 'data/repositories/tracking_repository_impl.dart';
import 'presentation/controllers/emergency_controller.dart';
import 'presentation/controllers/location_controller.dart';
import 'presentation/controllers/simulation_controller.dart';
import 'routing/app_router.dart';
import 'routing/route_paths.dart';

// Flag to toggle between local simulation mode and real backend integration
bool get isRemoteBackend => const bool.fromEnvironment('USE_REMOTE_BACKEND', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Data Source (Persistence & Recovery)
  final localDataSource = RequestLocalDataSourceImpl();

  // 2. Initialize Data Sources
  final mockTrackingDataSource = MockTrackingDataSource();
  final mockRequestDataSource = MockEmergencyRequestDataSource(trackingDataSource: mockTrackingDataSource);

  final httpClient = http.Client();
  final remoteRequestDataSource = RemoteEmergencyRequestDataSource(client: httpClient);
  final remoteTrackingDataSource = RemoteTrackingDataSource(client: httpClient);

  // 3. Initialize Repositories using Abstract Interfaces
  final emergencyRepository = EmergencyRequestRepositoryImpl(
    dataSource: isRemoteBackend ? remoteRequestDataSource : mockRequestDataSource,
    localDataSource: localDataSource,
  );

  final trackingRepository = TrackingRepositoryImpl(
    dataSource: isRemoteBackend ? remoteTrackingDataSource : mockTrackingDataSource,
  );

  // 4. Initialize Presentation Controllers
  final locationController = LocationController();
  final emergencyController = EmergencyController(repository: emergencyRepository);
  final simulationController = SimulationController(mockDataSource: mockRequestDataSource);

  // 5. Initialize App Router
  final appRouter = AppRouter(
    emergencyController: emergencyController,
    locationController: locationController,
    simulationController: simulationController,
    trackingRepository: trackingRepository,
  );

  runApp(UyirKappanBystanderApp(appRouter: appRouter));
}

/// Global ValueNotifier for toggling between Light and Dark mode across the application.
final ValueNotifier<ThemeMode> appThemeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

/// Root Application Widget for UyirKappan Module 1 (Bystander App).
class UyirKappanBystanderApp extends StatelessWidget {
  final AppRouter appRouter;

  const UyirKappanBystanderApp({
    super.key,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'UyirKappan — Bystander Emergency Response',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: RoutePaths.home,
          onGenerateRoute: appRouter.onGenerateRoute,
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
