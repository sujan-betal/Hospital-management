import 'package:flutter/material.dart';

import '../../data/patient_models.dart';
import '../patient_colors.dart';
import '../widgets/patient_common.dart';

/// "Profile Details" — patient overview card + editable registration form,
/// backed by `GET/PUT /api/patient/me`.
class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.profile,
    required this.onSave,
  });

  final PatientProfile profile;
  final Future<void> Function(PatientProfile updated) onSave;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _age;
  late final TextEditingController _insurance;
  late String _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.userName);
    _phone = TextEditingController(text: widget.profile.phone);
    _email = TextEditingController(text: widget.profile.email);
    _age = TextEditingController(
        text: widget.profile.age?.toString() ?? '');
    _insurance = TextEditingController(text: widget.profile.insuranceProvider);
    _gender = widget.profile.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _age.dispose();
    _insurance.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _name.text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'PT';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(PatientProfile(
        userId: widget.profile.userId,
        userName: _name.text.trim(),
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        age: int.tryParse(_age.text.trim()),
        gender: _gender,
        insuranceProvider: _insurance.text.trim(),
        status: widget.profile.status,
        role: widget.profile.role,
      ));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _overviewCard()),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: _editCard()),
                  ],
                )
              else ...[
                // Phones: stack the two cards full-width, each sized to its
                // content so the form fields + save button are never clipped.
                _overviewCard(),
                const SizedBox(height: 18),
                _editCard(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _overviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PatientColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [PatientColors.emerald, PatientColors.emeraldDark],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: PatientColors.emerald.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6)),
                ],
              ),
              alignment: Alignment.center,
              child: Text(_initials,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              _name.text.trim().isEmpty ? 'New Patient' : _name.text.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: PatientColors.textStrong),
            ),
          ),
          const SizedBox(height: 3),
          const Center(
            child: Text('Aura Medical Center · Patient Portal',
                style: TextStyle(fontSize: 11.5, color: PatientColors.textMuted)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PatientColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PatientColors.borderStrong),
            ),
            child: Column(
              children: [
                _detailRow('Phone', _phone.text.trim().isEmpty ? '—' : _phone.text.trim()),
                const SizedBox(height: 12),
                _detailRow(
                  'Age / Gender',
                  '${_age.text.trim().isEmpty ? '—' : '${_age.text.trim()} Y/O'}'
                  '${_gender.isNotEmpty ? ' · $_gender' : ''}',
                ),
                const SizedBox(height: 12),
                _detailRow(
                  'Insurance',
                  _insurance.text.trim().isEmpty
                      ? 'Self-Pay / None'
                      : _insurance.text.trim(),
                ),
                const SizedBox(height: 12),
                _detailRow('Triage Policy Status', 'Active', accent: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool accent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: PatientColors.textMuted)),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: accent
                      ? PatientColors.emeraldDark
                      : PatientColors.textStrong)),
        ),
      ],
    );
  }

  Widget _editCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PatientColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact & Registration Details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.textStrong)),
          const SizedBox(height: 4),
          const Text(
              'These details are stored in the hospital database and shared with your care team.',
              style: TextStyle(fontSize: 12, color: PatientColors.textMuted)),
          const SizedBox(height: 20),
          _field('Full Name', _name),
          const SizedBox(height: 14),
          _field('Phone Number', _phone, keyboard: TextInputType.phone),
          const SizedBox(height: 14),
          _field('Email Address', _email, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _field('Age', _age, keyboard: TextInputType.number),
          const SizedBox(height: 14),
          _genderField(),
          const SizedBox(height: 14),
          _field('Insurance Provider', _insurance),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: PatientPrimaryButton(
              label: _saving ? 'Saving…' : 'Update Details',
              icon: Icons.save_rounded,
              loading: _saving,
              onPressed: _saving ? () {} : _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: PatientColors.primary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14, color: PatientColors.textStrong),
          decoration: InputDecoration(
            hintText: label,
            hintStyle:
                const TextStyle(fontSize: 13, color: PatientColors.textHint),
            filled: true,
            fillColor: PatientColors.surfaceDeep,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: _fieldBorder(),
            enabledBorder: _fieldBorder(),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PatientColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PatientColors.borderStrong),
      );

  Widget _genderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: PatientColors.primary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final g in ['Male', 'Female', 'Other'])
              Material(
                color: _gender == g ? PatientColors.emerald : PatientColors.surfaceDeep,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => setState(() => _gender = g),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _gender == g
                              ? PatientColors.emerald
                              : PatientColors.borderStrong),
                    ),
                    child: Text(g,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _gender == g
                                ? Colors.white
                                : PatientColors.textBody)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}