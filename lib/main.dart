import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core/theme/app_theme.dart';
import 'data/datasources/adaptive/adaptive_datasources.dart';
import 'data/datasources/local/request_local_datasource.dart';
import 'data/datasources/mock/mock_emergency_request_datasource.dart';
import 'data/datasources/mock/mock_tracking_datasource.dart';
import 'data/datasources/remote/remote_auth_datasource.dart';
import 'data/datasources/remote/remote_emergency_request_datasource.dart';
import 'data/datasources/remote/remote_tracking_datasource.dart';
import 'data/datasources/remote/socket_service.dart';
import 'data/repositories/emergency_request_repository_impl.dart';
import 'data/repositories/tracking_repository_impl.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/emergency_controller.dart';
import 'presentation/controllers/location_controller.dart';
import 'presentation/controllers/simulation_controller.dart';
import 'routing/app_router.dart';
import 'routing/route_paths.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Data Source (Persistence & History)
  final localDataSource = RequestLocalDataSourceImpl();

  // 2. Initialize Real-Time Socket.IO Service & HTTP Client
  final httpClient = http.Client();
  final socketService = SocketService();

  // 3. Initialize Authentication (Module 1 Integration)
  final remoteAuthDataSource = RemoteAuthDataSource(client: httpClient);
  final authController = AuthController(authDataSource: remoteAuthDataSource);

  // Only connect to live Socket.IO if live backend mode is active
  if (useRemoteBackendNotifier.value) {
    socketService.connect(token: authController.token);
  }
  useRemoteBackendNotifier.addListener(() {
    if (useRemoteBackendNotifier.value) {
      socketService.connect(token: authController.token);
    } else {
      socketService.disconnect();
    }
  });

  // 4. Initialize Simulation DataSources
  final mockTrackingDataSource = MockTrackingDataSource(socketService: socketService);
  final mockRequestDataSource = MockEmergencyRequestDataSource(
    trackingDataSource: mockTrackingDataSource,
    socketService: socketService,
  );

  // 5. Initialize Remote REST DataSources
  final remoteRequestDataSource = RemoteEmergencyRequestDataSource(
    client: httpClient,
    tokenProvider: () async => authController.token,
    socketService: socketService,
  );
  final remoteTrackingDataSource = RemoteTrackingDataSource(
    client: httpClient,
    tokenProvider: () async => authController.token,
    socketService: socketService,
  );

  // 6. Initialize Adaptive DataSources (Seamless Live Backend <-> Simulation Mode)
  final adaptiveRequestDataSource = AdaptiveEmergencyRequestDataSource(
    remoteDataSource: remoteRequestDataSource,
    mockDataSource: mockRequestDataSource,
    useRemoteNotifier: useRemoteBackendNotifier,
  );
  final adaptiveTrackingDataSource = AdaptiveTrackingDataSource(
    remoteDataSource: remoteTrackingDataSource,
    mockDataSource: mockTrackingDataSource,
    useRemoteNotifier: useRemoteBackendNotifier,
  );

  // 7. Initialize Repositories using Abstract Interfaces
  final emergencyRepository = EmergencyRequestRepositoryImpl(
    dataSource: adaptiveRequestDataSource,
    localDataSource: localDataSource,
  );

  final trackingRepository = TrackingRepositoryImpl(
    dataSource: adaptiveTrackingDataSource,
  );

  // 8. Initialize Presentation Controllers
  final locationController = LocationController();
  final emergencyController = EmergencyController(
    repository: emergencyRepository,
    socketService: socketService,
  );
  final simulationController = SimulationController(mockDataSource: mockRequestDataSource);

  // 9. Initialize App Router
  final appRouter = AppRouter(
    emergencyController: emergencyController,
    locationController: locationController,
    simulationController: simulationController,
    trackingRepository: trackingRepository,
    authController: authController,
    socketService: socketService,
  );

  runApp(UyirKappanBystanderApp(
    appRouter: appRouter,
    authController: authController,
  ));
}

/// Global ValueNotifier for toggling between Light and Dark mode across the application.
final ValueNotifier<ThemeMode> appThemeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

/// Root Application Widget for UyirKappan Module 1 (Bystander App).
class UyirKappanBystanderApp extends StatelessWidget {
  final AppRouter appRouter;
  final AuthController? authController;

  const UyirKappanBystanderApp({
    super.key,
    required this.appRouter,
    this.authController,
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
          initialRoute: (authController?.isAuthenticated == true)
              ? RoutePaths.home
              : RoutePaths.auth,
          onGenerateRoute: appRouter.onGenerateRoute,
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
