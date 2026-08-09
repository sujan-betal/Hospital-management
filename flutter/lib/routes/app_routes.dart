// Define application routes here.

import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/login_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}