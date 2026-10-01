import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screens.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/finance/finance_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/lists/lists_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/today/today_screen.dart';
import 'adaptive_scaffold.dart';
import 'providers.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

StatefulShellBranch _branch(List<RouteBase> routes) => StatefulShellBranch(routes: routes);

final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ValueNotifier<bool>(ref.read(authProvider) != null);
  ref.listen(authProvider, (_, next) => signedIn.value = next != null);
  ref.onDispose(signedIn.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/today',
    refreshListenable: signedIn,
    redirect: (context, state) {
      final inAuth = state.matchedLocation.startsWith('/auth');
      if (!signedIn.value) return inAuth ? null : '/auth/sign-in';
      if (inAuth) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/sign-in', builder: (_, _) => const AuthScreen(mode: AuthMode.signIn)),
      GoRoute(path: '/auth/sign-up', builder: (_, _) => const AuthScreen(mode: AuthMode.signUp)),
      GoRoute(path: '/auth/forgot', builder: (_, _) => const AuthScreen(mode: AuthMode.forgot)),
      StatefulShellRoute(
        builder: (context, state, shell) => AdaptiveScaffold(shell: shell),
        navigatorContainerBuilder: (context, shell, children) => FadeThroughBranches(index: shell.currentIndex, children: children),
        branches: [
          _branch([GoRoute(path: '/today', builder: (_, _) => const TodayScreen())]),
          _branch([
            GoRoute(path: '/tasks', builder: (_, _) => const TasksScreen()),
            GoRoute(path: '/tasks/:id', builder: (_, s) => TasksScreen(selectedId: s.pathParameters['id'])),
          ]),
          _branch([
            GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
            GoRoute(path: '/calendar/:date', builder: (_, s) => CalendarScreen(date: s.pathParameters['date'])),
            GoRoute(path: '/calendar/:date/:eventId', builder: (_, s) => CalendarScreen(date: s.pathParameters['date'], eventId: s.pathParameters['eventId'])),
          ]),
          _branch([
            GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
            GoRoute(path: '/goals/:id', builder: (_, s) => GoalsScreen(selectedId: s.pathParameters['id'])),
          ]),
          _branch([
            GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
            GoRoute(path: '/notes/:id', builder: (_, s) => NotesScreen(selectedId: s.pathParameters['id'])),
          ]),
          _branch([
            GoRoute(path: '/lists', builder: (_, _) => const ListsScreen()),
            GoRoute(path: '/lists/:id', builder: (_, s) => ListsScreen(selectedId: s.pathParameters['id'])),
          ]),
          _branch([
            GoRoute(path: '/finance', builder: (_, _) => const FinanceScreen()),
            GoRoute(path: '/finance/:sel', builder: (_, s) => FinanceScreen(selected: s.pathParameters['sel'])),
          ]),
          _branch([GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
