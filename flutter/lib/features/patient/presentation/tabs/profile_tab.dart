import 'package:flutter/material.dart';

import '../../data/patient_models.dart';
import '../patient_colors.dart';

/// Tab 3 — Profile Details (overview + registration edit form).
class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.profile,
    required this.onSave,
    required this.saving,
  });

  final PatientProfile profile;
  final Future<bool> Function(PatientProfile profile) onSave;
  final bool saving;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _age;
  late final TextEditingController _insurance;
  String _gender = '';

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.profile.fullName);
    _phone = TextEditingController(text: widget.profile.phone);
    _email = TextEditingController(text: widget.profile.email);
    _age = TextEditingController(
        text: widget.profile.age == null ? '' : '${widget.profile.age}');
    _insurance = TextEditingController(text: widget.profile.insuranceProvider);
    _gender = widget.profile.gender;
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.fullName != widget.profile.fullName &&
        _fullName.text.isEmpty) {
      _fullName.text = widget.profile.fullName;
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _age.dispose();
    _insurance.dispose();
    super.dispose();
  }

  String get _initials {
    final name = widget.profile.fullName.trim();
    if (name.isEmpty) return 'PT';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length > 1) return parts[0][0] + parts[1][0];
    return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
  }

  Future<void> _save() async {
    final ageText = _age.text.trim();
    await widget.onSave(PatientProfile(
      fullName: _fullName.text.trim(),
      age: ageText.isEmpty ? null : int.tryParse(ageText),
      gender: _gender,
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      insuranceProvider: _insurance.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.profile.fullName.isEmpty
        ? 'New Patient'
        : widget.profile.fullName;

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final overview = _OverviewCard(
          initials: _initials,
          name: displayName,
          phone: widget.profile.phone,
          age: widget.profile.age,
          gender: widget.profile.gender,
        );
        final form = _DetailsForm(
          fullName: _fullName,
          phone: _phone,
          email: _email,
          age: _age,
          insurance: _insurance,
          gender: _gender,
          onGenderChanged: (v) => setState(() => _gender = v),
          saving: widget.saving,
          onSave: _save,
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: overview),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: form),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [overview, const SizedBox(height: 20), form],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.initials,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
  });

  final String initials;
  final String name;
  final String phone;
  final int? age;
  final String gender;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PatientColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PatientColors.emerald, Color(0xFF12463E)],
              ),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: PatientColors.emerald.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 14),
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: PatientColors.textStrong,
                  fontSize: 19,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          const Text('Member since 2026',
              style: TextStyle(color: PatientColors.textMuted, fontSize: 11)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PatientColors.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PatientColors.borderStrong),
            ),
            child: Column(
              children: [
                _detailRow('Phone', phone.isEmpty ? '—' : phone),
                const SizedBox(height: 12),
                _detailRow(
                    'Age / Gender',
                    (age != null ? '$age Y/O' : '—') +
                        (gender.isNotEmpty ? '  ·  $gender' : '')),
                const SizedBox(height: 12),
                const _detailRow(
                    'Triage Policy Status', 'Active',
                    valueColor: PatientColors.emeraldDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _detailRow extends StatelessWidget {
  const _detailRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: PatientColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        Text(value,
            textAlign: TextAlign.end,
            style: TextStyle(
                color: valueColor ?? PatientColors.textStrong,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _DetailsForm extends StatelessWidget {
  const _DetailsForm({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.age,
    required this.insurance,
    required this.gender,
    required this.onGenderChanged,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController fullName;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController age;
  final TextEditingController insurance;
  final String gender;
  final ValueChanged<String> onGenderChanged;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PatientColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: PatientColors.border)),
            ),
            child: const Text('Contact & Registration Details',
                style: TextStyle(
                    color: PatientColors.textStrong,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final twoCol = c.maxWidth >= 640;
              final field = (String label, Widget input) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: PatientColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      input,
                    ],
                  );

              final nameField = field(
                  'Full Name',
                  _input(fullName, Icons.person_outline_rounded,
                      keyboard: TextInputType.name));
              final phoneField = field(
                  'Phone Number',
                  _input(phone, Icons.smartphone_rounded,
                      keyboard: TextInputType.phone));
              final emailField = field(
                  'Email address',
                  _input(email, Icons.mail_outline_rounded,
                      keyboard: TextInputType.emailAddress));
              final ageField = field(
                  'Age',
                  _input(age, Icons.cake_outlined,
                      keyboard: TextInputType.number));
              final genderField = field('Gender', _genderInput());
              final insuranceField = field(
                  'Insurance Provider',
                  _input(insurance, Icons.shield_outlined));

              if (twoCol) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: nameField),
                        const SizedBox(width: 14),
                        Expanded(child: phoneField),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: emailField),
                        const SizedBox(width: 14),
                        Expanded(child: ageField),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: genderField),
                        const SizedBox(width: 14),
                        Expanded(child: insuranceField),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  nameField,
                  const SizedBox(height: 14),
                  phoneField,
                  const SizedBox(height: 14),
                  emailField,
                  const SizedBox(height: 14),
                  ageField,
                  const SizedBox(height: 14),
                  genderField,
                  const SizedBox(height: 14),
                  insuranceField,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PatientColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 16),
                  label: Text(saving ? 'Saving…' : 'Update Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PatientColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, IconData icon,
      {TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: PatientColors.textStrong, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 16, color: PatientColors.textHint),
        filled: true,
        fillColor: PatientColors.surfaceDeep,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PatientColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PatientColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PatientColors.primary),
        ),
      ),
    );
  }

  Widget _genderInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: PatientColors.surfaceDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PatientColors.borderStrong),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: gender.isEmpty ? null : gender,
          hint: const Text('Select…',
              style: TextStyle(
                  color: PatientColors.textHint, fontSize: 13)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded,
              color: PatientColors.textBody),
          style: const TextStyle(color: PatientColors.textStrong, fontSize: 13),
          items: ['Male', 'Female', 'Other']
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) {
            if (v != null) onGenderChanged(v);
          },
        ),
      ),
    );
  }
}
