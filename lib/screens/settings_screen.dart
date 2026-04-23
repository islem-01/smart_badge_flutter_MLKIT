// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth     = context.watch<AuthService>();
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.t('settings')),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Profil ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                radius: 28,
                child: Text(
                  auth.currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.currentUser?.name ?? '',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(auth.currentUser?.email ?? '',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      auth.isAdmin ? '👨‍💼 Admin' : '👤 Employé',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Apparence ───────────────────────────────────
          _SectionTitle('Apparence'),
          _SwitchTile(
            icon: Icons.dark_mode,
            iconColor: const Color(0xFF6366F1),
            title: 'Mode sombre',
            subtitle: 'Thème clair / sombre',
            value: settings.isDarkMode,
            onChanged: (_) => settings.toggleDarkMode(),
          ),
          const SizedBox(height: 12),

          // ── Langue ──────────────────────────────────────
          _SectionTitle(settings.t('language')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.language, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 12),
                const Text('Langue', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                _LangChip(settings: settings, lang: 'fr', label: '🇫🇷 FR'),
                const SizedBox(width: 4),
                _LangChip(settings: settings, lang: 'en', label: '🇬🇧 EN'),
                const SizedBox(width: 4),
                _LangChip(settings: settings, lang: 'ar', label: '🇹🇳 AR'),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── Notifications & Sons ─────────────────────────
          _SectionTitle('Notifications & Effets'),
          _SwitchTile(
            icon: Icons.notifications,
            iconColor: Colors.red,
            title: settings.t('notifs') == 'notifs'
                ? 'Notifications' : settings.t('notifs'),
            subtitle: 'Alertes lors du scan',
            value: settings.notificationsEnabled,
            onChanged: (_) => settings.toggleNotifications(),
          ),
          const SizedBox(height: 6),
          _SwitchTile(
            icon: Icons.volume_up,
            iconColor: Colors.green,
            title: 'Son de confirmation',
            subtitle: 'Bip lors du scan',
            value: settings.soundEnabled,
            onChanged: (_) => settings.toggleSound(),
          ),
          const SizedBox(height: 6),
          _SwitchTile(
            icon: Icons.vibration,
            iconColor: Colors.orange,
            title: settings.t('vibration'),
            subtitle: 'Retour haptique',
            value: settings.vibrationEnabled,
            onChanged: (_) => settings.toggleVibration(),
          ),
          const SizedBox(height: 12),

          // ── ML Kit Info ──────────────────────────────────
          _SectionTitle('ML Kit Services actifs'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: const [
                _MLKitRow('1', Icons.qr_code,    '1E3A8A',
                    'Barcode Scanning', 'Lecture QR Code badge'),
                _MLKitRow('2', Icons.text_fields,'7C3AED',
                    'Text Recognition', 'OCR – Extraction texte'),
                _MLKitRow('3', Icons.face,        '059669',
                    'Face Detection',   'Vérification identité'),
                _MLKitRow('4', Icons.translate,   'D97706',
                    'Translation',      'Traduction FR/EN/AR'),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── À propos ────────────────────────────────────
          _SectionTitle('À propos'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _InfoRow('Application', 'Smart Badge Scanner'),
                const Divider(height: 18),
                _InfoRow('Version',   '1.0.0'),
                const Divider(height: 18),
                _InfoRow('ML Kit',    '4 services actifs'),
                const Divider(height: 18),
                _InfoRow('Base',      'SQLite local'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A), letterSpacing: 1.1)),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title, subtitle;
  final bool     value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 2),
    child: SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _LangChip extends StatelessWidget {
  final SettingsProvider settings;
  final String lang, label;
  const _LangChip({
    required this.settings, required this.lang, required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final sel = settings.language == lang;
    return GestureDetector(
      onTap: () => settings.setLanguage(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 11,
            color: sel ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MLKitRow extends StatelessWidget {
  final String num, hexColor, label, desc;
  final IconData icon;
  const _MLKitRow(this.num, this.icon, this.hexColor, this.label, this.desc);

  Color get _color {
    final hex = int.tryParse('FF$hexColor', radix: 16) ?? 0xFF1E3A8A;
    return Color(hex);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: _color, borderRadius: BorderRadius.circular(6),
        ),
        child: Center(child: Text(num,
            style: const TextStyle(color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 10),
      Icon(icon, color: _color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13)),
          Text(desc, style: const TextStyle(
              fontSize: 11, color: Colors.grey)),
        ],
      )),
      Icon(Icons.check_circle, color: _color, size: 15),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      Text(value,  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );
}
