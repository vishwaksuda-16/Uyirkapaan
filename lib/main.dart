import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core/theme/app_theme.dart';
import 'data/datasources/adaptive/adaptive_datasources.dart';
import 'data/datasources/local/request_local_datasource.dart';
import 'data/datasources/mock/mock_emergency_request_datasource.dart';
import 'data/datasources/mock/mock_tracking_datasource.dart';
import 'data/datasources/remote/remote_auth_datasource.dart';
import 'data/datasources/remote/remote_emergency_request_datasource.dart';
import 'data/datasources/remote/socket_service.dart';
import 'data/repositories/emergency_request_repository_impl.dart';
import 'data/repositories/tracking_repository_impl.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/emergency_controller.dart';
import 'presentation/controllers/location_controller.dart';
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
  await authController.checkExistingAuth();
  if (!authController.isAuthenticated) {
    await authController.loginDemo();
  }

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

  // 4. Initialize Mock Data Sources (with live vehicle tracking & road routing)
  final mockTrackingDataSource = MockTrackingDataSource(
    socketService: socketService,
  );
  final mockRequestDataSource = MockEmergencyRequestDataSource(
    socketService: socketService,
    trackingDataSource: mockTrackingDataSource,
  );

  final adaptiveTrackingDataSource = AdaptiveTrackingDataSource(
    mockDataSource: mockTrackingDataSource,
    useRemoteNotifier: useRemoteBackendNotifier,
  );
  final trackingRepository = TrackingRepositoryImpl(
    dataSource: adaptiveTrackingDataSource,
  );

  // 5. Initialize Remote REST DataSource
  final remoteRequestDataSource = RemoteEmergencyRequestDataSource(
    client: httpClient,
    tokenProvider: () async => authController.token,
    socketService: socketService,
  );

  // 6. Initialize Adaptive DataSource (Seamless Live Backend <-> Local Mode)
  final adaptiveRequestDataSource = AdaptiveEmergencyRequestDataSource(
    remoteDataSource: remoteRequestDataSource,
    mockDataSource: mockRequestDataSource,
    useRemoteNotifier: useRemoteBackendNotifier,
  );

  // 7. Initialize Repository using Abstract Interface
  final emergencyRepository = EmergencyRequestRepositoryImpl(
    dataSource: adaptiveRequestDataSource,
    localDataSource: localDataSource,
  );

  // 8. Initialize Presentation Controllers
  final locationController = LocationController();
  final emergencyController = EmergencyController(
    repository: emergencyRepository,
    socketService: socketService,
  );

  // 9. Initialize App Router
  final appRouter = AppRouter(
    emergencyController: emergencyController,
    locationController: locationController,
    authController: authController,
    socketService: socketService,
    trackingRepository: trackingRepository,
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
