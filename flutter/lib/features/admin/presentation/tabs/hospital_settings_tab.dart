import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_models.dart';
import '../admin_colors.dart';
import '../widgets/admin_common.dart';

class HospitalSettingsTab extends StatefulWidget {
  const HospitalSettingsTab({
    super.key,
    required this.settings,
    required this.onSave,
  });

  final HospitalSettings settings;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  @override
  State<HospitalSettingsTab> createState() => _HospitalSettingsTabState();
}

class _HospitalSettingsTabState extends State<HospitalSettingsTab> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late int _copay;
  late int _emergencyMarkup;
  late bool _autoTelemetry;
  late int _sanitationInterval;
  late bool _autoDirty;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.settings.hospitalName);
    _address = TextEditingController(text: widget.settings.address);
    _copay = widget.settings.copayRate;
    _emergencyMarkup = widget.settings.emergencyMarkup;
    _autoTelemetry = widget.settings.autoTelemetry;
    _sanitationInterval = widget.settings.sanitationInterval;
    _autoDirty = widget.settings.autoDirty;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'hospital_name': _name.text.trim(),
        'address': _address.text.trim(),
        'copay_rate': _copay,
        'emergency_markup': _emergencyMarkup,
        'auto_telemetry': _autoTelemetry,
        'sanitation_interval': _sanitationInterval,
        'auto_dirty': _autoDirty,
      });
      showAdminToast(context, 'Clinical console updated — co-pay ratios & ICU alerts synchronized.');
    } catch (e) {
      showAdminToast(context, 'Failed to save settings: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.all(2),
        children: [
          _card(
            icon: Icons.apartment_rounded,
            title: 'Hospital Facility Profile',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 620;
                if (!isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field('Hospital Name', _name, TextInputType.text),
                      const SizedBox(height: 14),
                      _field(
                          'Base Currency', null, TextInputType.text,
                          hint: 'INR (Rs.) - Indian Rupee', disabled: true),
                      const SizedBox(height: 14),
                      _field('Facility Address', _address, TextInputType.text),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: _field('Hospital Name', _name, TextInputType.text)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _field('Base Currency', null, TextInputType.text,
                                hint: 'INR (Rs.) - Indian Rupee', disabled: true)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _field('Facility Address', _address, TextInputType.text),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _card(
            icon: Icons.credit_card_rounded,
            title: 'Co-pay & Emergency Markups',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final copay = _numberField('Standard Co-pay (%)', _copay,
                    (v) => setState(() => _copay = v));
                final markup = _numberField('Emergency Bed Markup (%)', _emergencyMarkup,
                    (v) => setState(() => _emergencyMarkup = v));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isWide)
                      Row(
                        children: [
                          Expanded(child: copay),
                          const SizedBox(width: 14),
                          Expanded(child: markup),
                        ],
                      )
                    else ...[
                      copay,
                      const SizedBox(height: 14),
                      markup,
                    ],
                    const SizedBox(height: 14),
                    _toggleRow(
                      title: 'Enable Auto ICU Telemetry Monitoring',
                      subtitle: 'Poll vital stats to central dashboard every 3s',
                      value: _autoTelemetry,
                      onChanged: (v) => setState(() => _autoTelemetry = v),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _card(
            icon: Icons.schedule_rounded,
            title: 'Ward Operations Settings',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final known = const [6, 12, 24];
                final cycle = ModalField(
                  label: 'Bed Sanitization Cycle',
                  field: DropdownButtonFormField<int>(
                    value: known.contains(_sanitationInterval) ? _sanitationInterval : 12,
                    isExpanded: true,
                    items: [
                      if (!known.contains(_sanitationInterval))
                        DropdownMenuItem(
                            value: _sanitationInterval,
                            child: Text('Every $_sanitationInterval Hours')),
                      const DropdownMenuItem(value: 6, child: Text('Every 6 Hours')),
                      const DropdownMenuItem(value: 12, child: Text('Every 12 Hours (Standard)')),
                      const DropdownMenuItem(value: 24, child: Text('Every 24 Hours')),
                    ],
                    onChanged: (v) => setState(() => _sanitationInterval = v ?? 12),
                    decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                );
                final trigger = ModalField(
                  label: 'Auto-Sanitize Trigger',
                  field: DropdownButtonFormField<String>(
                    value: _autoDirty ? 'on' : 'off',
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'on', child: Text('Immediately on Inpatient Discharge')),
                      DropdownMenuItem(value: 'off', child: Text('Manual logs only')),
                    ],
                    onChanged: (v) => setState(() => _autoDirty = v == 'on'),
                    decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                );
                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: cycle),
                      const SizedBox(width: 14),
                      Expanded(child: trigger),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cycle,
                    const SizedBox(height: 14),
                    trigger,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          AdminButton(
            label: _saving ? 'Saving…' : 'Save System Configuration',
            icon: Icons.save_rounded,
            expanded: true,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AdminColors.emerald600),
              const SizedBox(width: 9),
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            ],
          ),
          const Divider(height: 24, color: AdminColors.border),
          child,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController? controller,
      TextInputType type, {String? hint, bool disabled = false}) {
    return ModalField(
      label: label,
      field: TextField(
        controller: controller,
        enabled: !disabled,
        keyboardType: type,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textHint),
          filled: disabled,
          fillColor: disabled ? AdminColors.bgSubtle : null,
          border: modalFieldBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged,
      {String? hint}) {
    return ModalField(
      label: label,
      field: TextField(
        controller: TextEditingController(text: '$value'),
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
        decoration: InputDecoration(
          hintText: hint,
          border: modalFieldBorder(),
          prefixIcon: const Icon(Icons.percent_rounded, size: 16, color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AdminColors.bgSubtle,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textBody)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeColor: AdminColors.emerald500,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}