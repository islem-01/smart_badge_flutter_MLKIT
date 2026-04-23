// lib/screens/admin/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/export_service.dart';
import '../../providers/settings_provider.dart';
import '../../models/attendance_model.dart';
import '../auth/login_screen.dart';
import 'employee_list_screen.dart';
import '../employee/scan_screen.dart';
import '../settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _idx = 0;
  final _export = ExportService();

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
      _DashboardTab(exportService: _export),
      const EmployeeListScreen(),
      const ScanScreen(isAdminMode: true),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.admin_panel_settings, size: 20),
          const SizedBox(width: 8),
          Text(settings.t('dashboard')),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text(auth.currentUser?.name ?? '',
                style: const TextStyle(fontSize: 13))),
          ),
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
      body: IndexedStack(index: _idx, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard),
              label: settings.t('dashboard')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.people),
              label: settings.t('employees')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.qr_code_scanner),
              label: settings.t('scan')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: settings.t('settings')),
        ],
      ),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  final ExportService exportService;
  const _DashboardTab({required this.exportService});
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<Map<String, dynamic>> _weekly = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeekly();
  }

  Future<void> _loadWeekly() async {
    final data = await context.read<AttendanceService>().getWeeklyStats();
    if (mounted) setState(() { _weekly = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final settings    = context.watch<SettingsProvider>();
    final attendance  = context.watch<AttendanceService>();
    final stats       = attendance.todayStats;
    final today       = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        await attendance.loadTodayData();
        await _loadWeekly();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(settings.t('today'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ]),
          const SizedBox(height: 16),

          // Stats cards
          Row(children: [
            _StatCard(label: settings.t('total'),
                value: '${stats['total'] ?? 0}',
                icon: Icons.people, color: Colors.blue),
            const SizedBox(width: 10),
            _StatCard(label: settings.t('present'),
                value: '${stats['present'] ?? 0}',
                icon: Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            _StatCard(label: settings.t('absent'),
                value: '${stats['absent'] ?? 0}',
                icon: Icons.cancel, color: Colors.red),
          ]),
          const SizedBox(height: 16),

          // Export PDF
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () => widget.exportService.exportToPDF(today),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: Text(settings.t('export_pdf'),
                  style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            )),
          ]),
          const SizedBox(height: 16),

          // Graphique
          Text(settings.t('weekly_attendance'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8)],
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _weekly.isEmpty
                    ? const Center(child: Text('Aucune donnée'))
                    : BarChart(BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: ((stats['total'] ?? 10) as num).toDouble() + 2,
                        barGroups: _weekly.asMap().entries.map((e) {
                          final cnt = (e.value['count'] ?? 0) as num;
                          return BarChartGroupData(x: e.key, barRods: [
                            BarChartRodData(
                              toY: cnt.toDouble(),
                              color: const Color(0xFF1E3A8A),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ]);
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 24)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i >= _weekly.length) return const Text('');
                                final d = _weekly[i]['date'] as String;
                                return Text(d.substring(8, 10),
                                    style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      )),
          ),
          const SizedBox(height: 16),

          // Liste scans du jour
          Text(settings.t('today_scans'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...attendance.todayAttendance
              .map((a) => _AttendanceCard(a: a)),
        ]),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10,
            color: color.withValues(alpha: 0.8))),
      ]),
    ),
  );
}

class _AttendanceCard extends StatelessWidget {
  final Attendance a;
  const _AttendanceCard({required this.a});

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final isIn = a.checkOut == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: isIn
              ? Colors.green.shade100 : Colors.blue.shade100,
          child: Icon(isIn ? Icons.login : Icons.logout,
              color: isIn ? Colors.green : Colors.blue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.employeeName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(a.department,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('▶ ${_fmt(a.checkIn)}',
              style: const TextStyle(
                  fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
          if (a.checkOut != null)
            Text('■ ${_fmt(a.checkOut!)}',
                style: const TextStyle(
                    fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
          Text(a.workDurationFormatted,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
      ]),
    );
  }
}
