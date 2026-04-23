// lib/screens/admin/employee_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/employee_model.dart';
import '../../services/database_service.dart';
import '../../providers/settings_provider.dart';
import 'add_employee_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});
  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _db   = DatabaseService();
  List<Employee> _all      = [];
  List<Employee> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  Future<void> _load() async {
    final list = await _db.getAllEmployees();
    if (mounted) {
      setState(() {
        _all      = list.where((e) => e.role == 'employee').toList();
        _filtered = _all;
        _loading  = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((e) =>
        e.name.toLowerCase().contains(q) ||
        e.department.toLowerCase().contains(q) ||
        e.id.toLowerCase().contains(q)
      ).toList();
    });
  }

  Future<void> _delete(Employee emp) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Supprimer ${emp.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteEmployee(emp.id);
      _load();
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher un employé...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () { _searchCtrl.clear(); _filter(); },
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              filled: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${_filtered.length} employé(s)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Aucun employé trouvé'),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _EmpCard(
                        emp: _filtered[i],
                        onDelete: () => _delete(_filtered[i]),
                        onEdit: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                AddEmployeeScreen(employee: _filtered[i]))
                        ).then((_) => _load()),
                      ),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddEmployeeScreen()))
            .then((_) => _load()),
        icon: const Icon(Icons.person_add),
        label: Text(settings.t('add_employee')),
      ),
    );
  }
}

class _EmpCard extends StatelessWidget {
  final Employee emp;
  final VoidCallback onDelete, onEdit;
  const _EmpCard({
    required this.emp, required this.onDelete, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(emp.deptColor);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(emp.name[0].toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ),
        title: Text(emp.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(emp.department,
              style: TextStyle(color: color, fontSize: 11)),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit')   onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8), Text('Modifier'),
                ])),
            const PopupMenuItem(value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ])),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('ID',     emp.id),
                  _InfoRow('Email',  emp.email),
                  _InfoRow('QR',     emp.qrCode),
                ],
              )),
              Column(children: [
                QrImageView(
                    data: emp.qrCode, version: QrVersions.auto, size: 90),
                const Text('Badge QR',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String l, v;
  const _InfoRow(this.l, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text('$l : ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Expanded(child: Text(v,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}
