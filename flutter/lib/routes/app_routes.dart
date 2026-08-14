import 'package:flutter/material.dart';

import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/doctor/presentation/pages/doctor_dashboard_page.dart';
import '../features/patient/presentation/pages/patient_dashboard_page.dart';
import '../features/receptionist/presentation/pages/receptionist_dashboard_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String resetPassword = '/reset-password';
  static const String dashboardAdmin = '/dashboard/admin';
  static const String dashboardDoctor = '/dashboard/doctor';
  static const String dashboardReceptionist = '/dashboard/receptionist';
  static const String dashboardPatient = '/dashboard/patient';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');
    final path = uri.path.isEmpty ? settings.name : uri.path;
    switch (path) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case resetPassword:
        return MaterialPageRoute(
          builder: (_) => ResetPasswordPage(
            token: settings.arguments is String
                ? settings.arguments as String
                : uri.queryParameters['token'],
          ),
          settings: settings,
        );
      case dashboardAdmin:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardPage(),
          settings: settings,
        );
      case dashboardDoctor:
        return MaterialPageRoute(
          builder: (_) => const DoctorDashboardPage(),
          settings: settings,
        );
      case dashboardReceptionist:
        return MaterialPageRoute(
          builder: (_) => const ReceptionistDashboardPage(),
          settings: settings,
        );
      case dashboardPatient:
        return MaterialPageRoute(
          builder: (_) => const PatientDashboardPage(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}