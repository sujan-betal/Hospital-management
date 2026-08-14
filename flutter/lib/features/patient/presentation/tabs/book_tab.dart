import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../../admin/presentation/widgets/admin_common.dart';
import '../../data/patient_models.dart';

const List<String> kPatientSlots = [
  '09:30 AM',
  '10:15 AM',
  '11:00 AM',
  '01:15 PM',
  '03:30 PM',
  '04:45 PM',
];

/// "Book Appointment" — browse the hospital's doctors by specialty & rating,
/// then pick a free slot. Backed by `/api/patient/doctors`,
/// `/api/patient/appointments/booked-slots` and `POST /api/patient/appointments`.
class BookTab extends StatefulWidget {
  const BookTab({
    super.key,
    required this.doctors,
    required this.bookedSlots,
    required this.appointments,
    required this.today,
    required this.onBook,
  });

  final List<PatientDoctor> doctors;
  final List<BookedSlot> bookedSlots;
  final List<PatientAppointment> appointments;
  final String today;
  final Future<bool> Function(PatientDoctor doctor, String slot) onBook;

  @override
  State<BookTab> createState() => _BookTabState();
}

class _BookTabState extends State<BookTab> {
  String _specialty = 'All Specialties';
  bool _topRated = true;
  bool _booking = false;

  List<String> get _specialties =>
      widget.doctors.map((d) => d.specialty).toSet().toList();

  int get _topRatedCount =>
      widget.doctors.where((d) => d.isTopRated).length;

  Map<String, Set<String>> get _bookedByDoctor {
    final map = <String, Set<String>>{};
    void collect(String doctorName, String time) {
      map.putIfAbsent(doctorName, () => <String>{}).add(time);
    }

    for (final s in widget.bookedSlots) {
      collect(s.doctorName, s.time);
    }
    for (final a in widget.appointments) {
      if (a.date == widget.today && a.status.toUpperCase() != 'CANCELLED') {
        collect(a.doctorName, a.time);
      }
    }
    return map;
  }

  List<PatientDoctor> get _filtered {
    final list = _specialty == 'All Specialties'
        ? [...widget.doctors]
        : widget.doctors.where((d) => d.specialty == _specialty).toList();
    if (_topRated) {
      list.sort((a, b) => (b.rating).compareTo(a.rating));
    } else {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _header(),
        const SizedBox(height: 16),
        _filterChips(),
        const SizedBox(height: 16),
        if (_filtered.isEmpty)
          const AdminEmpty(
            message: 'No doctors available right now. The hospital has not added any active doctors yet.',
            icon: Icons.medical_services_rounded,
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final twoCol = c.maxWidth >= 900;
              return GridView.count(
                crossAxisCount: twoCol ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: twoCol ? 1.35 : 1.1,
                children: [
                  for (final doc in _filtered)
                    _DoctorCard(
                      doctor: doc,
                      slots: kPatientSlots,
                      booked: _bookedByDoctor[doc.name] ?? const {},
                      booking: _booking,
                      onBook: (slot) async {
                        setState(() => _booking = true);
                        await widget.onBook(doc, slot);
                        if (mounted) setState(() => _booking = false);
                      },
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book Consultation / Doctor Slot',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                SizedBox(height: 4),
                Text(
                    'Browse the hospital doctors by specialty & rating, then pick a slot',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(
                label: '${widget.doctors.length} Doctors',
                bg: AdminColors.bgSoft,
                fg: AppColors.emeraldDark,
                icon: Icons.people_rounded,
              ),
              Pill(
                label: '$_topRatedCount Top Rated',
                bg: AdminColors.amber50,
                fg: AdminColors.darkAmber,
                icon: Icons.workspace_premium_rounded,
              ),
              Material(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => setState(() => _topRated = !_topRated),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded,
                            size: 14, color: AppColors.emeraldDark),
                        const SizedBox(width: 5),
                        Text(_topRated ? 'Top Rated' : 'Name A-Z',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emeraldDark)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          label: 'All Specialties (${widget.doctors.length})',
          selected: _specialty == 'All Specialties',
          onTap: () => setState(() => _specialty = 'All Specialties'),
        ),
        for (final sp in _specialties)
          _chip(
            label:
                '$sp (${widget.doctors.where((d) => d.specialty == sp).length})',
            selected: _specialty == sp,
            onTap: () => setState(() => _specialty = sp),
          ),
      ],
    );
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected ? AdminColors.emerald600 : AdminColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AdminColors.emerald600 : AdminColors.borderLight),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textBody)),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.doctor,
    required this.slots,
    required this.booked,
    required this.booking,
    required this.onBook,
  });

  final PatientDoctor doctor;
  final List<String> slots;
  final Set<String> booked;
  final bool booking;
  final ValueChanged<String> onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AdminColors.bgSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.borderLight),
                ),
                alignment: Alignment.center,
                child: Text(doctor.initials,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.emerald700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(doctor.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                        ),
                        if (doctor.isTopRated) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.workspace_premium_rounded,
                              size: 15, color: Color(0xFFF59E0B)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AdminColors.bgSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(doctor.specialty,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.emerald700)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < doctor.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 13,
                            color: i < doctor.rating.round()
                                ? const Color(0xFFFBBF24)
                                : AdminColors.borderLight,
                          ),
                        const SizedBox(width: 5),
                        Text(doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Text(' · ${doctor.reviewCount} reviews',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.textMuted)),
                      ],
                    ),
                    if (doctor.experienceYears != null) ...[
                      const SizedBox(height: 3),
                      Text('${doctor.experienceYears}+ years experience',
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.textHint)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('AVAILABLE SLOTS TODAY',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                _slotChip(
                  slot: slot,
                  isBooked: booked.contains(slot),
                  disabled: booking,
                  onTap: () => onBook(slot),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AdminColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('OPD consultation fee',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const Spacer(),
              Text('Rs. 150',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotChip({
    required String slot,
    required bool isBooked,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    final color = isBooked
        ? const Color(0xFF9CAEA6)
        : const Color(0xFF0B2B26);
    return Material(
      color: isBooked ? AdminColors.bgSoft : AdminColors.bgSoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isBooked || disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isBooked ? AdminColors.border : AdminColors.borderLight),
            color: isBooked ? AdminColors.bgSoft : AdminColors.surface,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(slot,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: color)),
              if (isBooked) ...[
                const SizedBox(width: 5),
                const Text('Booked',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC0A24A))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
