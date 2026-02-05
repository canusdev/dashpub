import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dashpub_api/dashpub_api.dart';
import 'src/features/auth/auth_bloc.dart';
import 'src/features/auth/auth_pages.dart';
import 'src/features/setup/setup_page.dart';
import 'src/features/home/home_page.dart';
import 'src/features/package/package_detail_page.dart';
import 'src/features/settings/settings_page.dart';
import 'src/features/teams/teams_page.dart';
import 'src/features/teams/team_detail_page.dart';
import 'src/features/admin/admin_users_page.dart';
import 'src/features/admin/admin_teams_page.dart';
import 'src/features/admin/admin_packages_page.dart';
import 'src/features/settings/settings_cubit.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'src/utils/code_syntax_highlighter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  registerLanguages();

  usePathUrlStrategy();

  runApp(const DashpubApp());
}

DashpubApiClient apiClient = DashpubApiClient(
  const String.fromEnvironment('DASHPUB_API_URL'),
);

class DashpubApp extends StatelessWidget {
  final DashpubApiClient? clientOverride;
  const DashpubApp({super.key, this.clientOverride});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(clientOverride ?? apiClient)..add(AppStarted()),
        ),
        BlocProvider(create: (context) => SettingsCubit()),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              if (settingsState.settings == null &&
                  settingsState.error != null) {
                return ShadcnApp(
                  theme: ThemeData(
                    colorScheme: ColorSchemes.darkYellow,
                    radius: 0.9,
                    surfaceOpacity: 0.5,
                    surfaceBlur: 19.0,
                  ),
                  home: Scaffold(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(BootstrapIcons.wifiOff, size: 48),
                          const Gap(16),
                          Text(
                            'Cannot connect to server',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(8),
                          const Text(
                            'Please check your connection and that the server is running.',
                            style: TextStyle(color: Color(0xFF808080)),
                          ),
                          const Gap(24),
                          Button.primary(
                            onPressed: () {
                              context.read<SettingsCubit>().loadSettings();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (settingsState.isLoading || authState is AuthInitial) {
                return ShadcnApp(
                  theme: ThemeData(
                    colorScheme: ColorSchemes.darkYellow,
                    radius: 0.9,
                    surfaceOpacity: 0.5,
                    surfaceBlur: 19.0,
                  ),
                  home: const Scaffold(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              return ShadcnApp.router(
                title: settingsState.settings?.siteTitle ?? 'Dashpub',
                theme: ThemeData(
                  colorScheme: ColorSchemes.darkYellow.copyWith(),
                  radius: 0.9,
                  surfaceOpacity: 0.5,
                  surfaceBlur: 19.0,
                ),
                routerConfig: _router,
              );
            },
          );
        },
      ),
    );
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);
final _router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  navigatorKey: _rootNavigatorKey,

  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isSetup = state.uri.path == '/setup';
    final isLoggingIn =
        state.uri.path == '/login' || state.uri.path == '/register';

    if (authState is AuthSystemNotInitialized) {
      return isSetup ? null : '/setup';
    }

    if (isSetup && authState is! AuthSystemNotInitialized) {
      return '/';
    }

    if (authState is Unauthenticated && !isLoggingIn) {
      return '/login';
    }

    if (authState is Authenticated && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(path: '/setup', builder: (context, state) => const SetupPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // Backward compatibility for old links
    ShellRoute(
      navigatorKey: _shellNavigatorKey,

      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/package/:name',
          builder: (context, state) => PackageDetailPage(
            name: state.pathParameters['name']!,
            version: state.uri.queryParameters['v'] ?? 'latest',
          ),
        ),
        GoRoute(
          path: '/package/:name/:tab',
          builder: (context, state) => PackageDetailPage(
            name: state.pathParameters['name']!,
            version: state.uri.queryParameters['v'] ?? 'latest',
            tab: state.pathParameters['tab'],
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(path: '/teams', builder: (context, state) => const TeamsPage()),
        GoRoute(
          path: '/teams/:id',
          builder: (context, state) =>
              TeamDetailPage(teamId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersPage(),
        ),
        GoRoute(
          path: '/admin/teams',
          builder: (context, state) => const AdminTeamsPage(),
        ),
        GoRoute(
          path: '/admin/packages',
          builder: (context, state) => const AdminPackagesPage(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => ShadcnApp(
    theme: ThemeData(colorScheme: ColorSchemes.darkYellow, radius: 0.9),
    home: Scaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(BootstrapIcons.exclamationTriangle, size: 48),
            const Gap(16),
            Text(
              'Page not found',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text('The page ${state.uri.path} does not exist.').muted(),
            const Gap(24),
            Button.primary(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  ),
);

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Row(
        children: [
          _Sidebar(),
          const VerticalDivider(),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                const Divider(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = GoRouterState.of(context).uri.toString();
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final title = state.settings?.siteTitle?.isNotEmpty == true
                  ? state.settings!.siteTitle!
                  : 'Dashpub';
              final logoUrl = state.settings?.logoUrl;

              return Padding(
                padding: const EdgeInsets.only(left: 1, top: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Gap(24),
                    if (logoUrl != null && logoUrl.isNotEmpty)
                      Image.network(
                        logoUrl,
                        height: 32,
                        width: 32,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/dashpub.png',
                              height: 32,
                              width: 32,
                            ),
                      )
                    else
                      Image.asset('assets/dashpub.png', height: 32, width: 32),
                    const Gap(12),
                    Text(
                      title,
                      style: theme.typography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          NavigationSidebar(
            index: (uri == '/' || uri.startsWith('/pkg'))
                ? 0
                : (uri == '/teams' || uri.startsWith('/teams/'))
                ? 1
                : (uri == '/settings')
                ? 2
                : -1,
            onSelected: (index) {
              if (index == 0) context.go('/');
              if (index == 1) context.go('/teams');
              if (index == 2) context.go('/settings');
            },
            children: const [
              NavigationItem(
                child: Row(
                  children: [
                    Icon(BootstrapIcons.search, size: 18),
                    Gap(12),
                    Text('Explore'),
                  ],
                ),
              ),
              NavigationItem(
                child: Row(
                  children: [
                    Icon(BootstrapIcons.people, size: 18),
                    Gap(12),
                    Text('Teams'),
                  ],
                ),
              ),
              NavigationItem(
                child: Row(
                  children: [
                    Icon(BootstrapIcons.gear, size: 18),
                    Gap(12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated && state.user.isAdmin) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'ADMIN',
                        style: theme.typography.xSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.mutedForeground,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Gap(8),
                    NavigationSidebar(
                      index: uri.startsWith('/admin/users')
                          ? 0
                          : uri.startsWith('/admin/teams')
                          ? 1
                          : uri.startsWith('/admin/packages')
                          ? 2
                          : -1,
                      onSelected: (index) {
                        if (index == 0) context.go('/admin/users');
                        if (index == 1) context.go('/admin/teams');
                        if (index == 2) context.go('/admin/packages');
                      },
                      children: const [
                        NavigationItem(
                          child: Row(
                            children: [
                              Icon(BootstrapIcons.peopleFill, size: 18),
                              Gap(12),
                              Text('Users'),
                            ],
                          ),
                        ),
                        NavigationItem(
                          child: Row(
                            children: [
                              Icon(BootstrapIcons.microsoftTeams, size: 18),
                              Gap(12),
                              Text('Teams'),
                            ],
                          ),
                        ),
                        NavigationItem(
                          child: Row(
                            children: [
                              Icon(BootstrapIcons.boxSeamFill, size: 18),
                              Gap(12),
                              Text('Packages'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const Spacer(),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(),
                      const Gap(16),
                      Row(
                        children: [
                          Avatar(
                            initials: state.user.name?.isNotEmpty == true
                                ? state.user.name!.substring(0, 1).toUpperCase()
                                : state.user.email
                                      .substring(0, 1)
                                      .toUpperCase(),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.user.name ?? 'User',
                                  style: theme.typography.small.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  state.user.email,
                                  style: theme.typography.xSmall.copyWith(
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Button.ghost(
                        onPressed: () =>
                            context.read<AuthBloc>().add(LogoutRequested()),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(BootstrapIcons.boxArrowRight, size: 14),
                            Gap(8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Button.primary(
                  onPressed: () => context.go('/login'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(BootstrapIcons.person, size: 18),
                      Gap(8),
                      Text('Login'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          Spacer(),
          // Placeholder for theme toggle or user menu
        ],
      ),
    );
  }
}
