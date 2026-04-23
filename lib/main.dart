// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/settings_provider.dart';
import 'services/auth_service.dart';
import 'services/attendance_service.dart';
import 'services/notif_service.dart';
import 'utils/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/employee/employee_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await NotifService.instance.init();

  final settings = SettingsProvider();
  await settings.loadSettings();

  final auth = AuthService();
  await auth.restoreSession();

  await Permission.camera.request();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => AttendanceService()),
    ],
    child: const SmartBadgeApp(),
  ));
}

class SmartBadgeApp extends StatelessWidget {
  const SmartBadgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth     = context.watch<AuthService>();
    final isRtl    = settings.language == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: MaterialApp(
        title: 'Smart Badge Scanner',
        debugShowCheckedModeBanner: false,
        theme:      AppTheme.lightTheme,
        darkTheme:  AppTheme.darkTheme,
        themeMode:  settings.themeMode,
        locale:     settings.locale,
        home: _buildHome(auth),
      ),
    );
  }

  Widget _buildHome(AuthService auth) {
    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.isAdmin)     return const AdminHomeScreen();
    return const EmployeeHomeScreen();
  }
}
