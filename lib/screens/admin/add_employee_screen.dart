// lib/screens/admin/add_employee_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/employee_model.dart';
import '../../services/database_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  const AddEmployeeScreen({super.key, this.employee});
  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _db        = DatabaseService();
  String _dept     = 'Informatique';
  bool   _loading  = false;

  final List<String> _depts = [
    'Informatique','Ressources Humaines','Finance',
    'Marketing','Direction','Commercial',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameCtrl.text  = widget.employee!.name;
      _emailCtrl.text = widget.employee!.email;
      _dept           = widget.employee!.department;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (widget.employee == null) {
        final id = 'emp_${const Uuid().v4().substring(0, 8)}';
        await _db.addEmployee(Employee(
          id: id, name: _nameCtrl.text.trim(),
          department: _dept, email: _emailCtrl.text.trim(),
          role: 'employee', qrCode: 'BADGE_$id',
          createdAt: DateTime.now(),
        ));
      } else {
        await _db.updateEmployee(widget.employee!.copyWith(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          department: _dept,
        ));
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.employee == null
            ? 'Employé ajouté !' : 'Employé modifié !'),
        backgroundColor: Colors.green,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier employé' : 'Ajouter employé'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            const CircleAvatar(radius: 42,
                backgroundColor: Color(0x1A1E3A8A),
                child: Icon(Icons.person, size: 44, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              decoration: _dec('Nom complet *', Icons.person_outline),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Requis' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('Email *', Icons.email_outlined),
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'Requis';
                if (!v!.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _dept,
              decoration: _dec('Département *', Icons.business),
              items: _depts.map((d) =>
                  DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _dept = v ?? _dept),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Mot de passe par défaut: emp123',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                )),
              ]),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit
                        ? 'Enregistrer les modifications'
                        : 'Ajouter l\'employé',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
