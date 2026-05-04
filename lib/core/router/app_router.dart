import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/athletes/screens/athletes_screen.dart';
import '../../features/athletes/screens/athlete_detail_screen.dart';
import '../../features/athletes/models/athlete_model.dart';
import '../../features/dojos/screens/dojos_screen.dart';
import '../../features/dojos/screens/dojo_detail_screen.dart';
import '../../features/dojos/models/dojo_model.dart';
import '../../features/videos/screens/videos_screen.dart';
import '../../features/videos/screens/video_detail_screen.dart';
import '../../features/videos/models/video_model.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/technique/screens/technique_flow_screen.dart';
import '../../features/technique/screens/technique_tree_screen.dart';
import '../../features/technique/screens/my_flow_screen.dart';
import '../../features/mypage/screens/mypage_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/game_plans/screens/game_plans_screen.dart';
import '../../features/game_plans/screens/game_plan_editor_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/forum_thread_screen.dart';
import '../../features/community/models/forum_models.dart';
import '../../features/dojo_owner/screens/dojo_owner_screen.dart';
import '../../features/dojo_owner/screens/class_checkin_screen.dart';
import '../../features/instructor/screens/instructor_marketplace_screen.dart';
import '../../features/instructor/screens/course_detail_screen.dart';
import '../../features/instructor/models/course_model.dart' as instructor;
import '../../features/training_journal/screens/training_journal_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';
import '../../screens/auth/simple_login_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

// Only mypage requires login — everything else is freely browsable
const _protectedRoutes = [
  '/mypage',
];

class AppRouter {
  static final _storage = const FlutterSecureStorage();
  // Pre-cached at startup — avoids async blank screen on first load
  static bool _isAuthenticated = false;

  static Future<void> preloadAuthState() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      _isAuthenticated = token != null && token.isNotEmpty;
    } catch (_) {
      _isAuthenticated = false;
    }
  }

  static String? _redirectGuard(
    BuildContext context,
    GoRouterState state,
  ) {
    final location = state.matchedLocation;
    if (!_isAuthenticated && _protectedRoutes.contains(location)) {
      return '/login-magic';
    }
    return null;
  }

  // Keep for backward compat
  static final router = GoRouter(
    initialLocation: '/',
    redirect: _redirectGuard,
    routes: [
      // Legacy login (outside shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const SimpleLoginScreen(),
      ),

      // Magic-link login screen (new dark design)
      GoRoute(
        path: '/login-magic',
        builder: (context, state) => const LoginScreen(),
      ),

      // Deep-link handler: jiuflow://auth/verify?token=xxx
      GoRoute(
        path: '/auth/verify/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return _AuthVerifyPage(token: token);
        },
      ),

      // Athletes (standalone, not in bottom nav)
      GoRoute(
        path: '/athletes',
        builder: (context, state) => const AthletesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final athlete = AthleteModel(id: id, name: id);
              return AthleteDetailScreen(athlete: athlete);
            },
          ),
        ],
      ),

      // News
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsScreen(),
      ),

      // Community forum
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final thread = ForumThread(
                id: id,
                title: 'スレッド',
                body: '',
                authorName: '',
                createdAt: DateTime.now(),
              );
              return ForumThreadScreen(thread: thread);
            },
          ),
        ],
      ),

      // Instructor Marketplace
      GoRoute(
        path: '/instructors',
        builder: (context, state) => const InstructorMarketplaceScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final fallback = instructor.CourseModel(
                id: state.pathParameters['id'] ?? '',
                title: '講座',
                instructorName: 'インストラクター',
                description: '',
                priceYen: 0,
                lessonCount: 1,
              );
              return CourseDetailScreen(
                course: state.extra is instructor.CourseModel
                    ? state.extra as instructor.CourseModel
                    : fallback,
              );
            },
          ),
        ],
      ),

      // Training Journal
      GoRoute(
        path: '/training-journal',
        builder: (context, state) => const TrainingJournalScreen(),
      ),

      // Subscription
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),

      // Dojo owner dashboard
      GoRoute(
        path: '/dojo-owner',
        builder: (context, state) => const DojoOwnerScreen(),
        routes: [
          GoRoute(
            path: 'checkin/:classId',
            builder: (context, state) {
              final classId = state.pathParameters['classId'] ?? '';
              return ClassCheckinScreen(
                classId: classId,
                className: state.uri.queryParameters['name'] ?? 'クラス',
              );
            },
          ),
        ],
      ),

      // Dojos (accessible via routes but not in bottom nav)
      GoRoute(
        path: '/dojos',
        builder: (context, state) => const DojosScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final dojo = DojoModel(id: id, name: id);
              return DojoDetailScreen(dojo: dojo);
            },
          ),
        ],
      ),

      // Game plans (accessible via routes but not in bottom nav)
      GoRoute(
        path: '/game-plans',
        builder: (context, state) => const GamePlansScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) =>
                const GamePlanEditorScreen(plan: null),
          ),
        ],
      ),

      // Shell with bottom nav (4 tabs: home, technique, videos, mypage)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/technique-flow',
                builder: (context, state) => const TechniqueTreeScreen(),
                routes: [
                  GoRoute(
                    path: 'canvas',
                    builder: (context, state) => const TechniqueFlowScreen(),
                  ),
                  GoRoute(
                    path: 'my-flow',
                    builder: (context, state) => const MyFlowScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/videos',
                builder: (context, state) => const VideosScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      final video = VideoModel(id: id, title: id);
                      return VideoDetailScreen(video: video);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mypage',
                builder: (context, state) => const MyPageScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Transient page shown when the user taps the magic-link email.
/// It dispatches [AuthVerifyTokenRequested] and redirects on result.
class _AuthVerifyPage extends StatefulWidget {
  const _AuthVerifyPage({required this.token});
  final String token;

  @override
  State<_AuthVerifyPage> createState() => _AuthVerifyPageState();
}

class _AuthVerifyPageState extends State<_AuthVerifyPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch token verification after first frame so BLoC is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<FeatureAuthBloc>()
          .add(AuthVerifyTokenRequested(token: widget.token));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeatureAuthBloc, FeatureAuthState>(
      listener: (context, state) {
        if (state is FeatureAuthAuthenticated) {
          context.go('/');
        } else if (state is FeatureAuthError) {
          context.go('/login-magic');
        }
      },
      child: const Scaffold(
        backgroundColor: Color(0xFF09090B),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
      ),
    );
  }
}
