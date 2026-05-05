import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/server_provider.dart';
import 'providers/class_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/student_provider.dart';
import 'features/role_selection/role_selection_screen.dart';
import 'features/admin/screens/admin_pin_screen.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'features/admin/screens/manage_classes_screen.dart';
import 'features/admin/screens/create_class_screen.dart';
import 'features/admin/screens/live_attendance_screen.dart';
import 'features/admin/screens/pending_users_screen.dart';
import 'features/admin/screens/export_screen.dart';
import 'features/student/screens/student_connect_screen.dart';
import 'features/student/screens/student_login_screen.dart';
import 'features/student/screens/pending_approval_screen.dart';
import 'features/student/screens/active_class_screen.dart';
import 'features/student/screens/mark_attendance_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, _) => const RoleSelectionScreen()),
    GoRoute(path: '/admin/pin', builder: (ctx, _) => const AdminPinScreen()),
    GoRoute(path: '/admin/home', builder: (ctx, _) => const AdminHomeScreen()),
    GoRoute(path: '/admin/classes', builder: (ctx, _) => const ManageClassesScreen()),
    GoRoute(path: '/admin/classes/create', builder: (ctx, _) => const CreateClassScreen()),
    GoRoute(
      path: '/admin/live/:classId',
      builder: (ctx, state) =>
          LiveAttendanceScreen(classId: state.pathParameters['classId']!),
    ),
    GoRoute(path: '/admin/pending', builder: (ctx, _) => const PendingUsersScreen()),
    GoRoute(path: '/admin/export', builder: (ctx, _) => const ExportScreen()),
    GoRoute(path: '/student/connect', builder: (ctx, _) => const StudentConnectScreen()),
    GoRoute(path: '/student/login', builder: (ctx, _) => const StudentLoginScreen()),
    GoRoute(path: '/student/pending', builder: (ctx, _) => const PendingApprovalScreen()),
    GoRoute(path: '/student/class', builder: (ctx, _) => const ActiveClassScreen()),
    GoRoute(path: '/student/mark', builder: (ctx, _) => const MarkAttendanceScreen()),
  ],
);

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServerProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()..initialize()),
      ],
      child: MaterialApp.router(
        title: 'Attendance App',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
