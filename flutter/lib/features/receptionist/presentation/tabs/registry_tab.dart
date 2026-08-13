import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../../admin/presentation/widgets/admin_common.dart';
import '../../data/receptionist_models.dart';

/// Patient registry — searchable list with a register modal (POST /api/patient).
class RegistryTab extends StatefulWidget {
  const RegistryTab({super.key, required this.patients, required this.onAdd});

  final List<PatientRecord> patients;
  final Future<bool> Function(Map<String, dynamic> payload) onAdd;

  @override
  State<RegistryTab> createState() => _RegistryTabState();
}

class _RegistryTabState extends State<RegistryTab> {
  String _query = '';

  List<PatientRecord> get _filtered {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return widget.patients;
    return widget.patients.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.phone.contains(q) ||
          p.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openRegister() async {
    final ok = await showAdminModal<bool>(
      context,
      title: 'Register New Patient',
      subtitle: 'Create a patient record at the front desk',
      child: _PatientForm(onSubmit: widget.onAdd),
    );
    if (ok == true && mounted) {
      showAdminToast(context, 'Patient registered');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(
          title: 'Patient Registry',
          subtitle: '${widget.patients.length} registered patients',
          action: AdminButton(
            label: 'Register Patient',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: _openRegister,
          ),
        ),
        const SizedBox(height: 16),
        AdminSearchField(
          hint: 'Search by name, phone or email…',
          value: _query,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        if (_filtered.isEmpty)
          const AdminEmpty(message: 'No patients match your search.')
        else
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _filtered.length; i++) ...[
                  _PatientTile(patient: _filtered[i]),
                  if (i != _filtered.length - 1)
                    const Divider(height: 1, color: AdminColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient});

  final PatientRecord patient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [patient.phone, patient.gender, if (patient.age != null) '${patient.age} yrs']
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Pill(
            label: patient.status == 'ACTIVE' ? 'ACTIVE' : 'INACTIVE',
            bg: patient.status == 'ACTIVE'
                ? AdminColors.teal50
                : AdminColors.amber50,
            fg: patient.status == 'ACTIVE'
                ? AdminColors.emerald600
                : AdminColors.darkAmber,
          ),
        ],
      ),
    );
  }
}

class _PatientForm extends StatefulWidget {
  const _PatientForm({required this.onSubmit});

  final Future<bool> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<_PatientForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _age = TextEditingController();
  final _insurance = TextEditingController();
  String _gender = 'Male';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _age.dispose();
    _insurance.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2 || _phone.text.trim().length < 6) {
      setState(() => _error = 'Name and phone number are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await widget.onSubmit({
      'user_name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'age': int.tryParse(_age.text.trim()),
      'gender': _gender,
      'insurance_provider': _insurance.text.trim(),
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModalField(
          label: 'Full name *',
          field: TextField(
            controller: _name,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
                hintText: 'e.g. Emma Watson', border: modalFieldBorder()),
          ),
        ),
        const SizedBox(height: 14),
        ModalField(
          label: 'Phone number *',
          field: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
                hintText: '+91 98765 43210', border: modalFieldBorder()),
          ),
        ),
        const SizedBox(height: 14),
        ModalField(
          label: 'Email',
          field: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
                hintText: 'patient@email.com', border: modalFieldBorder()),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ModalField(
                label: 'Age',
                field: TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration:
                      InputDecoration(hintText: '32', border: modalFieldBorder()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModalField(
                label: 'Gender',
                field: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      border: Border.all(color: AdminColors.border),
                      borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender,
                      isExpanded: true,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textDark),
                      items: ['Male', 'Female', 'Other']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _gender = v ?? _gender),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ModalField(
          label: 'Insurance provider',
          field: TextField(
            controller: _insurance,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
                hintText: 'e.g. Star Health / Self-Pay',
                border: modalFieldBorder()),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(fontSize: 12, color: AdminColors.rose)),
        ],
        const SizedBox(height: 20),
        AdminButton(
          label: _saving ? 'Saving…' : 'Register Patient',
          icon: Icons.check_rounded,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}