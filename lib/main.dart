import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/booking/booking_bloc.dart';
import 'blocs/video/video_bloc.dart';
import 'blocs/member/member_bloc.dart';
import 'blocs/dojo_mode/dojo_mode_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
// import 'screens/auth/test_login_screen.dart';
import 'screens/auth/simple_login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/simple_home_screen.dart';
import 'screens/instructor/instructor_dashboard_screen.dart';
import 'utils/demo_auth.dart';
import 'themes/colorful_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  runApp(const JitsuFlowApp());
}

class JitsuFlowApp extends StatelessWidget {
  const JitsuFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
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
      child: MaterialApp(
        title: 'JitsuFlow',
        theme: ColorfulTheme.lightTheme,
        darkTheme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF1B5E20),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Hiragino Sans',
        ),
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const SimpleLoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const SimpleHomeScreen(),
          '/instructor/dashboard': (context) => const InstructorDashboardScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // Check if already logged in
      final isLoggedIn = await DemoAuth.isLoggedIn();
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_martial_arts,
                size: 120,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'JitsuFlow',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'ブラジリアン柔術トレーニング',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}