import 'package:flutter/material.dart';

import '../../data/doctor_models.dart';
import '../doctor_colors.dart';

/// Shared dark-theme form field used across the doctor modals.
class DoctorModalField extends StatelessWidget {
  const DoctorModalField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.maxLines = 1,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: DoctorColors.emeraldLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: DoctorColors.textFaint),
            filled: true,
            fillColor: DoctorColors.canvas,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DoctorColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DoctorColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DoctorColors.emerald),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdown mirroring the frontend `<select>` patient picker.
class DoctorPatientPicker extends StatelessWidget {
  const DoctorPatientPicker({
    super.key,
    required this.patients,
    required this.selected,
    required this.onChanged,
  });

  final List<String> patients;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Patient',
            style: TextStyle(
                color: DoctorColors.emeraldLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: DoctorColors.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DoctorColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected.isEmpty ? null : selected,
              hint: const Text('-- Choose patient --',
                  style: TextStyle(color: DoctorColors.textFaint, fontSize: 13)),
              isExpanded: true,
              dropdownColor: DoctorColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: DoctorColors.textBody),
              items: patients
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Wraps a modal body in the dark clinical chrome used by the web app.
Future<T?> showDoctorModal<T>({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => Dialog(
      backgroundColor: DoctorColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: DoctorColors.borderAccent),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: DoctorColors.emeraldLight),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: DoctorColors.textBody, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(color: DoctorColors.border),
              const SizedBox(height: 14),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Prescription write form (frontend `Write Medical Prescription` modal).
class PrescriptionModalBody extends StatefulWidget {
  const PrescriptionModalBody({
    super.key,
    required this.patients,
    this.initialPatient = '',
    required this.onSave,
  });

  final List<String> patients;
  final String initialPatient;
  final void Function(String patient, List<DoctorMedicine> medicines, String notes)
      onSave;

  @override
  State<PrescriptionModalBody> createState() => _PrescriptionModalBodyState();
}

class _PrescriptionModalBodyState extends State<PrescriptionModalBody> {
  late String _patient = widget.initialPatient;
  final _notes = TextEditingController();
  late final List<_MedRow> _rows = [
    _MedRow(),
  ];

  @override
  void dispose() {
    _notes.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_patient.isEmpty) return;
    final meds = _rows
        .where((r) => r.name.text.trim().isNotEmpty)
        .map((r) => DoctorMedicine(
              name: r.name.text.trim(),
              dosage: r.dosage.text.trim(),
              duration: r.duration.text.trim(),
            ))
        .toList();
    if (meds.isEmpty) return;
    widget.onSave(_patient, meds, _notes.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoctorPatientPicker(
          patients: widget.patients,
          selected: _patient,
          onChanged: (v) => setState(() => _patient = v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('Medication Details',
                  style: TextStyle(
                      color: DoctorColors.emeraldLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => setState(() => _rows.add(_MedRow())),
              child: const Text('+ Add Medication',
                  style: TextStyle(
                      color: DoctorColors.emeraldLight,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        ..._rows.asMap().entries.map((e) => _MedRowInput(
              key: ValueKey(e.key),
              row: e.value,
              onRemove: _rows.length > 1
                  ? () => setState(() => _rows.removeAt(e.key))
                  : null,
            )),
        const SizedBox(height: 16),
        DoctorModalField(
          controller: _notes,
          label: 'Additional Advice / Notes',
          hint: 'E.g. Drink plenty of water, avoid strenuous activity for a week.',
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: DoctorColors.textBody, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.send_rounded, size: 15),
              label: const Text('Dispatch Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DoctorColors.emerald,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MedRow {
  final name = TextEditingController();
  final dosage = TextEditingController();
  final duration = TextEditingController();

  void dispose() {
    name.dispose();
    dosage.dispose();
    duration.dispose();
  }
}

class _MedRowInput extends StatelessWidget {
  const _MedRowInput({super.key, required this.row, this.onRemove});

  final _MedRow row;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DoctorColors.canvas.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DoctorColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _cell(row.name, 'Medicine name'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _cell(row.dosage, 'Dosage'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _cell(row.duration, 'Days'),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: const Icon(Icons.close_rounded,
                        size: 15, color: DoctorColors.textFaint),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(TextEditingController c, String hint) => TextField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: DoctorColors.textFaint),
          filled: true,
          fillColor: DoctorColors.canvas,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: DoctorColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: DoctorColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: DoctorColors.emerald),
          ),
        ),
      );
}

/// Lab diagnostics request form (frontend `Request Lab & Diagnostics` modal).
class LabModalBody extends StatefulWidget {
  const LabModalBody({
    super.key,
    required this.patients,
    this.initialPatient = '',
    required this.onSave,
  });

  final List<String> patients;
  final String initialPatient;
  final void Function(String patient, String testType, String priority) onSave;

  @override
  State<LabModalBody> createState() => _LabModalBodyState();
}

class _LabModalBodyState extends State<LabModalBody> {
  late String _patient = widget.initialPatient;
  final _test = TextEditingController();
  String _priority = 'routine';

  @override
  void dispose() {
    _test.dispose();
    super.dispose();
  }

  void _save() {
    if (_patient.isEmpty || _test.text.trim().isEmpty) return;
    widget.onSave(_patient, _test.text.trim(), _priority);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoctorPatientPicker(
          patients: widget.patients,
          selected: _patient,
          onChanged: (v) => setState(() => _patient = v),
        ),
        const SizedBox(height: 16),
        DoctorModalField(
          controller: _test,
          label: 'Requested Diagnostics / Panels',
          hint: 'E.g. HbA1c, Liver Function Panel, MRI Head',
        ),
        const SizedBox(height: 16),
        const Text('Triage Priority',
            style: TextStyle(
                color: DoctorColors.emeraldLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: ['routine', 'urgent', 'stat']
              .map((p) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _priority = p),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _priority == p
                                ? DoctorColors.emerald
                                : DoctorColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _priority == p
                                    ? DoctorColors.emerald
                                    : DoctorColors.border),
                          ),
                          child: Text(p.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _priority == p
                                      ? Colors.white
                                      : DoctorColors.textBody)),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: DoctorColors.textBody, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.science_rounded, size: 15),
              label: const Text('Dispatch Lab Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DoctorColors.emerald,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Consultation notes form (frontend `Start Diagnosis Notes` modal).
class ConsultationModalBody extends StatefulWidget {
  const ConsultationModalBody({
    super.key,
    required this.patients,
    this.initialPatient = '',
    required this.onSave,
  });

  final List<String> patients;
  final String initialPatient;
  final void Function(String patient, String diagnosis, String treatment, String notes)
      onSave;

  @override
  State<ConsultationModalBody> createState() => _ConsultationModalBodyState();
}

class _ConsultationModalBodyState extends State<ConsultationModalBody> {
  late String _patient = widget.initialPatient;
  final _diagnosis = TextEditingController();
  final _treatment = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _diagnosis.dispose();
    _treatment.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (_patient.isEmpty || _diagnosis.text.trim().isEmpty) return;
    widget.onSave(
      _patient,
      _diagnosis.text.trim(),
      _treatment.text.trim(),
      _notes.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoctorPatientPicker(
          patients: widget.patients,
          selected: _patient,
          onChanged: (v) => setState(() => _patient = v),
        ),
        const SizedBox(height: 16),
        DoctorModalField(
          controller: _diagnosis,
          label: 'Diagnosis & Assessment',
          hint: 'E.g. Mild gastric irritation, early stage influenza',
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        DoctorModalField(
          controller: _treatment,
          label: 'Treatment / Intervention Plan',
          hint: 'E.g. Bed rest, daily temperature tracking, follow-up in 3 days.',
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        DoctorModalField(
          controller: _notes,
          label: 'Clinical Notes (Confidential)',
          hint: 'E.g. Patient showed anxiety during assessment.',
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: DoctorColors.textBody, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.medical_services_rounded, size: 15),
              label: const Text('Save Diagnostics Notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DoctorColors.emerald,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
