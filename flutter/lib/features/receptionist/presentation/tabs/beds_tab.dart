import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/data/admin_models.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../../admin/presentation/widgets/admin_common.dart';

/// Ward & bed console — read-only overview with status / occupant changes
/// (PUT /api/receptionist/beds/{id}).
class BedsTab extends StatelessWidget {
  const BedsTab({super.key, required this.beds, required this.onUpdate});

  final List<Bed> beds;
  final Future<void> Function(Bed bed, Map<String, dynamic> payload) onUpdate;

  @override
  Widget build(BuildContext context) {
    final occupied =
        beds.where((b) => b.status == BedStatus.occupied).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(
          title: 'Ward & Bed Console',
          subtitle: '$occupied of ${beds.length} beds occupied',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 1200 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.5,
          children: [
            KpiCard(
              label: 'Total Beds',
              value: '${beds.length}',
              sub: 'across all wards',
              icon: Icons.meeting_room_rounded,
              iconColor: AdminColors.blue,
            ),
            KpiCard(
              label: 'Occupied',
              value: '$occupied',
              sub: 'in active use',
              icon: Icons.person_pin_rounded,
              iconColor: AdminColors.emerald600,
            ),
            KpiCard(
              label: 'Sanitizing',
              value: '${beds.where((b) => b.status == BedStatus.sanitizing).length}',
              sub: 'being prepared',
              icon: Icons.cleaning_services_rounded,
              iconColor: AdminColors.amber,
            ),
            KpiCard(
              label: 'Available',
              value: '${beds.where((b) => b.status == BedStatus.available).length}',
              sub: 'ready for admit',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AdminColors.teal,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (beds.isEmpty)
          const AdminEmpty(message: 'No beds loaded yet.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 340,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.55,
            ),
            itemCount: beds.length,
            itemBuilder: (context, i) => _BedCard(bed: beds[i], onUpdate: onUpdate),
          ),
      ],
    );
  }
}

class _BedCard extends StatelessWidget {
  const _BedCard({required this.bed, required this.onUpdate});

  final Bed bed;
  final Future<void> Function(Bed bed, Map<String, dynamic> payload) onUpdate;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (bed.status) {
      BedStatus.occupied => (AdminColors.teal50, AdminColors.teal),
      BedStatus.available => (AdminColors.blue50, AdminColors.blue),
      BedStatus.sanitizing => (AdminColors.amber50, AdminColors.darkAmber),
      BedStatus.reserved => (AdminColors.purple50, AdminColors.purple),
    };

    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bed_rounded,
                    size: 19, color: fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bed.id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${bed.ward} · Floor ${bed.floor}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 18, color: AppColors.textMuted),
                onSelected: (v) => onUpdate(bed, {'status': v}),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'AVAILABLE', child: Text('Mark Available')),
                  const PopupMenuItem(
                      value: 'OCCUPIED', child: Text('Mark Occupied')),
                  const PopupMenuItem(
                      value: 'SANITIZING', child: Text('Mark Sanitizing')),
                  const PopupMenuItem(
                      value: 'RESERVED', child: Text('Mark Reserved')),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  bed.patient?.isNotEmpty == true ? bed.patient! : 'No patient',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: bed.patient?.isNotEmpty == true
                        ? AppColors.textDark
                        : AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pill(label: bed.status.name, bg: bg, fg: fg),
            ],
          ),
        ],
      ),
    );
  }
}