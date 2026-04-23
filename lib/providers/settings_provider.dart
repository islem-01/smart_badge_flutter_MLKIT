// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool   _isDarkMode            = false;
  bool   _notificationsEnabled  = true;
  bool   _soundEnabled          = true;
  bool   _vibrationEnabled      = true;
  String _language              = 'fr';

  bool   get isDarkMode           => _isDarkMode;
  bool   get notificationsEnabled => _notificationsEnabled;
  bool   get soundEnabled         => _soundEnabled;
  bool   get vibrationEnabled     => _vibrationEnabled;
  String get language             => _language;

  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Locale get locale {
    switch (_language) {
      case 'ar': return const Locale('ar');
      case 'en': return const Locale('en');
      default:   return const Locale('fr');
    }
  }

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    _isDarkMode           = p.getBool('darkMode')      ?? false;
    _notificationsEnabled = p.getBool('notifications') ?? true;
    _soundEnabled         = p.getBool('sound')         ?? true;
    _vibrationEnabled     = p.getBool('vibration')     ?? true;
    _language             = p.getString('language')    ?? 'fr';
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    (await SharedPreferences.getInstance()).setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    (await SharedPreferences.getInstance()).setBool('notifications', _notificationsEnabled);
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    (await SharedPreferences.getInstance()).setBool('sound', _soundEnabled);
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    (await SharedPreferences.getInstance()).setBool('vibration', _vibrationEnabled);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    (await SharedPreferences.getInstance()).setString('language', lang);
    notifyListeners();
  }

  // ── Traductions ──────────────────────────────────────
  String t(String key) {
    return _strings[_language]?[key] ?? _strings['fr']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'fr': {
      'app_title': 'Smart Badge Scanner',
      'scan': 'Scanner', 'employees': 'Employés',
      'history': 'Historique', 'settings': 'Paramètres',
      'dashboard': 'Tableau de bord', 'present': 'Présent',
      'absent': 'Absent', 'check_in': 'Entrée', 'check_out': 'Sortie',
      'total': 'Total', 'today': "Aujourd'hui", 'name': 'Nom',
      'department': 'Département', 'login': 'Connexion',
      'logout': 'Déconnexion', 'email': 'Email',
      'password': 'Mot de passe', 'welcome': 'Bienvenue',
      'export_pdf': 'Exporter PDF', 'scan_badge': 'Scanner le badge',
      'my_attendance': 'Ma présence', 'add_employee': 'Ajouter employé',
      'statistics': 'Statistiques', 'weekly_attendance': 'Présence semaine',
      'today_scans': 'Scans du jour', 'verify_face': 'Vérifier visage',
      'ocr_scan': 'Scanner texte (OCR)', 'no_history': 'Aucun historique',
      'work_duration': 'Durée travail', 'delete': 'Supprimer',
      'cancel': 'Annuler', 'confirm': 'Confirmer', 'save': 'Enregistrer',
    },
    'en': {
      'app_title': 'Smart Badge Scanner',
      'scan': 'Scan', 'employees': 'Employees',
      'history': 'History', 'settings': 'Settings',
      'dashboard': 'Dashboard', 'present': 'Present',
      'absent': 'Absent', 'check_in': 'Check In', 'check_out': 'Check Out',
      'total': 'Total', 'today': 'Today', 'name': 'Name',
      'department': 'Department', 'login': 'Login',
      'logout': 'Logout', 'email': 'Email',
      'password': 'Password', 'welcome': 'Welcome',
      'export_pdf': 'Export PDF', 'scan_badge': 'Scan Badge',
      'my_attendance': 'My Attendance', 'add_employee': 'Add Employee',
      'statistics': 'Statistics', 'weekly_attendance': 'Weekly Attendance',
      'today_scans': 'Today Scans', 'verify_face': 'Verify Face',
      'ocr_scan': 'Scan Text (OCR)', 'no_history': 'No history',
      'work_duration': 'Work Duration', 'delete': 'Delete',
      'cancel': 'Cancel', 'confirm': 'Confirm', 'save': 'Save',
    },
    'ar': {
      'app_title': 'ماسح الشارات الذكي',
      'scan': 'مسح', 'employees': 'الموظفون',
      'history': 'السجل', 'settings': 'الإعدادات',
      'dashboard': 'لوحة التحكم', 'present': 'حاضر',
      'absent': 'غائب', 'check_in': 'دخول', 'check_out': 'خروج',
      'total': 'المجموع', 'today': 'اليوم', 'name': 'الاسم',
      'department': 'القسم', 'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج', 'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور', 'welcome': 'مرحباً',
      'export_pdf': 'تصدير PDF', 'scan_badge': 'مسح الشارة',
      'my_attendance': 'حضوري', 'add_employee': 'إضافة موظف',
      'statistics': 'إحصائيات', 'weekly_attendance': 'حضور الأسبوع',
      'today_scans': 'مسوحات اليوم', 'verify_face': 'التحقق من الوجه',
      'ocr_scan': 'قراءة النص', 'no_history': 'لا يوجد سجل',
      'work_duration': 'مدة العمل', 'delete': 'حذف',
      'cancel': 'إلغاء', 'confirm': 'تأكيد', 'save': 'حفظ',
    },
  };
}
