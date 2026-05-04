import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'l10n/app_localizations.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/booking/booking_bloc.dart';
import 'blocs/video/video_bloc.dart';
import 'blocs/member/member_bloc.dart';
import 'blocs/dojo_mode/dojo_mode_bloc.dart';
import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart' as feature_auth;
import 'features/auth/services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  try {
    await initializeDateFormatting('ja_JP', null);
  } catch (e) {
    debugPrint('initializeDateFormatting error: $e');
  }

  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('NotificationService error: $e');
  }

  try {
    await AppRouter.preloadAuthState();
  } catch (e) {
    debugPrint('preloadAuthState error: $e');
  }

  runApp(const JiuFlowApp());
}

class JiuFlowApp extends StatefulWidget {
  const JiuFlowApp({super.key});

  @override
  State<JiuFlowApp> createState() => _JiuFlowAppState();
}

class _JiuFlowAppState extends State<JiuFlowApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
    ApiClient.onUnauthorized = () => AppRouter.router.go('/login-magic');
  }

  void _initDeepLinks() async {
    // Handle app opened from a Universal Link (cold start)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handleLink(initialLink);
    } catch (_) {}

    // Handle Universal Links while app is running
    _appLinks.uriLinkStream.listen(_handleLink, onError: (_) {});
  }

  void _handleLink(Uri uri) {
    // Only handle magic-link verify paths
    final path = uri.path;
    if (path != '/auth/magic/verify' && path != '/auth/verify') return;
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      AppRouter.router.go('/auth/verify/$token');
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authService = AuthService(apiClient);

    return MultiBlocProvider(
      providers: [
        // Legacy AuthBloc (email+password flows)
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
        // Feature AuthBloc (magic-link / token verification)
        BlocProvider<feature_auth.FeatureAuthBloc>(
          create: (context) => feature_auth.FeatureAuthBloc(authService),
        ),
        BlocProvider<BookingBloc>(
          create: (context) => BookingBloc(),
        ),
        BlocProvider<VideoBloc>(
          create: (context) => VideoBloc(),
        ),
        BlocProvider<MemberBloc>(
          create: (context) => MemberBloc(),
        ),
        BlocProvider<DojoModeBloc>(
          create: (context) => DojoModeBloc(),
        ),
      ],
      child: MaterialApp.router(
        title: 'JiuFlow',
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
