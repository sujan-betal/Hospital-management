import 'package:flutter/material.dart';

import '../../data/patient_models.dart';
import '../patient_colors.dart';
import '../widgets/patient_common.dart';

/// Tab 2 — Book Appointment (doctor directory + slot picker).
class BookTab extends StatelessWidget {
  const BookTab({
    super.key,
    required this.doctors,
    required this.selectedSpecialty,
    required this.sortByName,
    required this.booking,
    required this.onSelectSpecialty,
    required this.onToggleSort,
    required this.onBookSlot,
    required this.bookedTimesFor,
  });

  final List<PatientDoctor> doctors;
  final String selectedSpecialty;
  final bool sortByName;
  final bool booking;
  final void Function(String) onSelectSpecialty;
  final VoidCallback onToggleSort;
  final void Function(PatientDoctor doctor, String slot) onBookSlot;
  final Set<String> Function(String doctorName) bookedTimesFor;

  int get _topRatedCount => doctors.where((d) => d.isTopRated).length;

  List<String> get _specialties {
    final seen = <String>{};
    for (final d in doctors) {
      seen.add(d.specialty.isEmpty ? 'General Medicine' : d.specialty);
    }
    return seen.toList();
  }

  int _countFor(String specialty) =>
      doctors.where((d) => (d.specialty.isEmpty ? 'General Medicine' : d.specialty) == specialty).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: PatientColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PatientColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Book Consultation / Doctor Slot',
                      style: TextStyle(
                          color: PatientColors.textStrong,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      'Browse the hospital\'s doctors by specialty & rating, then pick a slot',
                      style: const TextStyle(
                          color: PatientColors.textBody, fontSize: 12)),
                ],
              );
              final chips = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summaryChip(
                    icon: Icons.people_rounded,
                    label: '${doctors.length} Doctors',
                    color: PatientColors.primary,
                    soft: PatientColors.surfaceAlt,
                    line: PatientColors.borderStrong,
                  ),
                  _summaryChip(
                    icon: Icons.workspace_premium_rounded,
                    label: '$_topRatedCount Top Rated',
                    color: PatientColors.amberText,
                    soft: PatientColors.amberSoft,
                    line: PatientColors.amberLine,
                  ),
                  InkWell(
                    onTap: onToggleSort,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: PatientColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: PatientColors.borderStrong),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded,
                              size: 14, color: PatientColors.primary),
                          const SizedBox(width: 6),
                          Text(sortByName ? 'Name A–Z' : 'Top Rated',
                              style: const TextStyle(
                                  color: PatientColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
              if (c.maxWidth >= 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 12),
                    chips,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 14), chips],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip(
              label: 'All Specialties (${doctors.length})',
              selected: selectedSpecialty == 'All Specialties',
              onTap: () => onSelectSpecialty('All Specialties'),
            ),
            for (final sp in _specialties)
              _filterChip(
                label: '$sp (${_countFor(sp)})',
                selected: selectedSpecialty == sp,
                onTap: () => onSelectSpecialty(sp),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: PatientColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: PatientColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.medical_services_rounded,
                    size: 40, color: PatientColors.textFaint),
                SizedBox(height: 10),
                Text('No doctors available right now',
                    style: TextStyle(
                        color: PatientColors.textMid,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('The hospital has not added any active doctors yet.',
                    style:
                        TextStyle(color: PatientColors.textMuted, fontSize: 12)),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final cards = filtered
                  .map((doc) => _DoctorCard(
                        doctor: doc,
                        bookedTimes: bookedTimesFor(doc.name),
                        booking: booking,
                        onBookSlot: (slot) => onBookSlot(doc, slot),
                      ))
                  .toList();
              if (wide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 520,
                    mainAxisExtent: 400,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) => cards[i],
                );
              }
              return Column(
                children: [
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: card,
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  List<PatientDoctor> _filtered() {
    final list = doctors.where((d) {
      final sp = d.specialty.isEmpty ? 'General Medicine' : d.specialty;
      return selectedSpecialty == 'All Specialties' || sp == selectedSpecialty;
    }).toList();
    if (sortByName) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color soft,
    required Color line,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? PatientColors.emerald
                : PatientColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected
                    ? PatientColors.emerald
                    : PatientColors.borderStrong),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : PatientColors.textMid)),
        ),
      );
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.doctor,
    required this.bookedTimes,
    required this.booking,
    required this.onBookSlot,
  });

  final PatientDoctor doctor;
  final Set<String> bookedTimes;
  final bool booking;
  final void Function(String) onBookSlot;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PatientColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PatientColors.borderStrong),
                ),
                child: Text(doctor.initials,
                    style: const TextStyle(
                        color: PatientColors.emeraldDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(doctor.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: PatientColors.textStrong,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                        ),
                        if (doctor.isTopRated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: PatientColors.amberSoft,
                              borderRadius: BorderRadius.circular(5),
                              border:
                                  Border.all(color: PatientColors.amberLine),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium_rounded,
                                    size: 10, color: PatientColors.amberText),
                                SizedBox(width: 3),
                                Text('Top Rated',
                                    style: TextStyle(
                                        color: PatientColors.amberText,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PatientColors.emeraldSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                          doctor.specialty.isEmpty
                              ? 'General Medicine'
                              : doctor.specialty,
                          style: const TextStyle(
                              color: PatientColors.emeraldDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        PatientStars(rating: doctor.rating),
                        const SizedBox(width: 6),
                        Text(doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: PatientColors.textStrong,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                        Text('  ·  ${doctor.reviewCount} reviews',
                            style: const TextStyle(
                                color: PatientColors.textMuted, fontSize: 10)),
                      ],
                    ),
                    if (doctor.experienceYears != null &&
                        doctor.experienceYears! > 0) ...[
                      const SizedBox(height: 2),
                      Text('${doctor.experienceYears}+ years experience',
                          style: const TextStyle(
                              color: PatientColors.textMuted, fontSize: 10)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('AVAILABLE SLOTS TODAY',
              style: TextStyle(
                  color: PatientColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: patientSlots.map((slot) {
              final booked = bookedTimes.contains(slot);
              return InkWell(
                onTap: (booking || booked) ? null : () => onBookSlot(slot),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: booked
                        ? PatientColors.surfaceAlt
                        : PatientColors.surfaceDeep,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: PatientColors.borderStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(slot,
                          style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: booked
                                  ? PatientColors.textHint
                                  : PatientColors.textStrong)),
                      if (booked) ...[
                        const SizedBox(width: 6),
                        Text('BOOKED',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: PatientColors.amberText)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PatientColors.border)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('OPD consultation fee',
                    style: TextStyle(
                        color: PatientColors.textMuted, fontSize: 12)),
                Text('Rs. 150',
                    style: TextStyle(
                        color: PatientColors.textStrong,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
