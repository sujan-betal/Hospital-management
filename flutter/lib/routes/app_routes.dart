import 'package:flutter/material.dart';

import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String dashboardAdmin = '/dashboard/admin';
  static const String dashboardDoctor = '/dashboard/doctor';
  static const String dashboardReceptionist = '/dashboard/receptionist';
  static const String dashboardPatient = '/dashboard/patient';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case dashboardAdmin:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardPage(),
          settings: settings,
        );
      case dashboardDoctor:
        return _portalRoute(settings, 'Doctor');
      case dashboardReceptionist:
        return _portalRoute(settings, 'Receptionist');
      case dashboardPatient:
        return _portalRoute(settings, 'Patient');
      default:
        return null;
    }
  }

  static Route<dynamic> _portalRoute(RouteSettings settings, String portal) {
    return MaterialPageRoute(
      builder: (_) => DashboardPage(portal: portal),
      settings: settings,
    );
  }
}