import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session_store.dart';
import '../core/di/registry.dart';
import '../core/widgets/common.dart';
import '../features/auth/auth_page.dart';
import '../features/bookings/bookings_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/public/landing_page.dart';
import '../features/public/public_pages.dart';
import '../features/public/search_page.dart';
import '../features/services/services_page.dart';
import '../features/settings/hours_page.dart';
import '../features/settings/settings_page.dart';
import 'shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: di<SessionStore>(),
  redirect: (context, state) {
    final path = state.uri.path;
    final private = path == '/onboarding' ||
        path == '/my-bookings' ||
        path.startsWith('/app/');
    if (private && !di<SessionStore>().isAuthenticated) {
      return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    if (path.startsWith('/app/') &&
        di<SessionStore>().workspaceId.value == null) {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/find',
      builder: (context, state) => const ConfigurationGate(child: FindPage()),
    ),
    GoRoute(
      path: '/business/:slug',
      builder: (_, s) => ConfigurationGate(
        child: BusinessPage(slug: s.pathParameters['slug']!),
      ),
    ),
    GoRoute(
      path: '/book/:workspaceId/:serviceId',
      builder: (_, s) => ConfigurationGate(
        child: BookPage(
          workspaceId: s.pathParameters['workspaceId']!,
          serviceId: s.pathParameters['serviceId']!,
        ),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (_, s) => ConfigurationGate(
        child: AuthPage(mode: 'login', from: s.uri.queryParameters['from']),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (_, s) => ConfigurationGate(
        child: AuthPage(mode: 'register', from: s.uri.queryParameters['from']),
      ),
    ),
    GoRoute(
      path: '/reset',
      builder: (context, state) =>
          const ConfigurationGate(child: AuthPage(mode: 'reset')),
    ),
    GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage()),
    GoRoute(
        path: '/my-bookings',
        builder: (context, state) => const MyBookingsPage()),
    ShellRoute(
      builder: (context, state, child) => WorkShell(child: child),
      routes: [
        GoRoute(
          path: '/app/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
            path: '/app/services',
            builder: (context, state) => const ServicesPage()),
        GoRoute(
            path: '/app/bookings',
            builder: (context, state) => const BookingsPage()),
        GoRoute(
            path: '/app/hours', builder: (context, state) => const HoursPage()),
        GoRoute(
            path: '/app/plan', builder: (context, state) => const PlanPage()),
        GoRoute(
            path: '/app/settings',
            builder: (context, state) => const SettingsPage()),
      ],
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Notice(message: 'Página não encontrada.')),
  ),
);
