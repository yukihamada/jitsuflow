import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/booking/booking_bloc.dart';
import 'blocs/video/video_bloc.dart';
import 'blocs/member/member_bloc.dart';
import 'blocs/dojo_mode/dojo_mode_bloc.dart';
import 'screens/screenshots/screenshot_video_screen.dart';
import 'screens/screenshots/screenshot_booking_screen.dart';
import 'screens/screenshots/screenshot_profile_screen.dart';
import 'screens/home/simple_home_screen.dart';
import 'themes/colorful_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  
  // 引数でどの画面を表示するか決定
  final args = const String.fromEnvironment('SCREENSHOT_MODE', defaultValue: 'home');
  
  runApp(ScreenshotApp(mode: args));
}

class ScreenshotApp extends StatelessWidget {
  final String mode;
  
  const ScreenshotApp({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    Widget screen;
    
    switch (mode) {
      case 'video':
        screen = const ScreenshotVideoScreen();
        break;
      case 'booking':
        screen = const ScreenshotBookingScreen();
        break;
      case 'profile':
        screen = const ScreenshotProfileScreen();
        break;
      case 'home':
      default:
        screen = const SimpleHomeScreen();
    }
    
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
        home: screen,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}