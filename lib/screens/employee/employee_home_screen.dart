// lib/screens/employee/employee_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../providers/settings_provider.dart';
import '../../models/attendance_model.dart';
import '../auth/login_screen.dart';
import 'scan_screen.dart';
import 'my_attendance_screen.dart';
import '../settings_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});
  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AttendanceService>().loadTodayData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth     = context.watch<AuthService>();

    final screens = [
      _EmployeeDashboard(),
      const ScanScreen(),
      const MyAttendanceScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.t('app_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: screens[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.qr_code_scanner),
              label: settings.t('scan')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: settings.t('history')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: settings.t('settings')),
        ],
      ),
    );
  }
}

class _EmployeeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth       = context.watch<AuthService>();
    final attendance = context.watch<AttendanceService>();
    final settings   = context.watch<SettingsProvider>();
    final user       = auth.currentUser;

    final todayRecord = attendance.todayAttendance
        .where((a) => a.employeeId == user?.id)
        .isNotEmpty
        ? attendance.todayAttendance
            .firstWhere((a) => a.employeeId == user!.id)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte bienvenue
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    radius: 28,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'E',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${settings.t('welcome')}, ${user?.name ?? ''}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(user?.department ?? '',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13)),
                    ],
                  )),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: todayRecord != null
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    todayRecord != null
                        ? todayRecord.checkOut == null
                            ? '✅ Présent depuis ${_fmt(todayRecord.checkIn)}'
                            : '🏠 Parti à ${_fmt(todayRecord.checkOut!)}'
                        : '⏳ Pas encore scanné aujourd\'hui',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (todayRecord != null) ...[
            Text('Ma journée',
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _TodayCard(record: todayRecord),
            const SizedBox(height: 20),
          ],

          // Quick scan button
          GestureDetector(
            onTap: () {
              // Navigate to scan tab
              final state = context.findAncestorStateOfType<
                  _EmployeeHomeScreenState>();
              state?.setState(() => state._idx = 1);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.green, Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Icon(Icons.qr_code_scanner,
                    color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(settings.t('scan_badge'),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Appuyez pour scanner',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12)),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}

class _TodayCard extends StatelessWidget {
  final Attendance record;
  const _TodayCard({required this.record});
  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Expanded(child: _TimeInfo('Entrée', _fmt(record.checkIn),
            Colors.green, Icons.login)),
        Container(height: 40, width: 1, color: Colors.grey.shade300),
        Expanded(child: _TimeInfo('Sortie',
            record.checkOut != null ? _fmt(record.checkOut!) : '--:--',
            record.checkOut != null ? Colors.red : Colors.grey,
            Icons.logout)),
        Container(height: 40, width: 1, color: Colors.grey.shade300),
        Expanded(child: _TimeInfo('Durée',
            record.workDurationFormatted, Colors.blue, Icons.timer)),
      ]),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label, time;
  final Color color;
  final IconData icon;
  const _TimeInfo(this.label, this.time, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(height: 4),
    Text(time, style: TextStyle(color: color,
        fontWeight: FontWeight.bold, fontSize: 14)),
    Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
  ]);
}
