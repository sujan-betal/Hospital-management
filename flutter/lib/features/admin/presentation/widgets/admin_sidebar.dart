import 'package:flutter/material.dart';

import '../admin_colors.dart';

/// Which admin console tab is currently open.
enum AdminTab {
  overview('Overview', Icons.dashboard_rounded),
  beds('Wards & Beds', Icons.meeting_room_rounded),
  admissions('Patient Admissions', Icons.person_add_alt_1_rounded),
  doctors('Attending Doctors', Icons.medical_services_rounded),
  tasks('Clinical Tasks', Icons.assignment_turned_in_rounded),
  staff('Staff Credentials', Icons.badge_rounded),
  settings('Hospital Settings', Icons.settings_rounded),
  payments('Payments', Icons.payments_rounded);

  const AdminTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.current,
    required this.userName,
    required this.userEmail,
    required this.onSelect,
    required this.onSignOut,
  });

  final AdminTab current;
  final String userName;
  final String userEmail;
  final ValueChanged<AdminTab> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: AdminColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Brand(),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('ADMINISTRATION',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AdminColors.emerald500.withOpacity(0.55))),
          ),
          const SizedBox(height: 8),
          Expanded(child: _Menu(current: current, onSelect: onSelect)),
          _BottomProfile(
              userName: userName, userEmail: userEmail, onSignOut: onSignOut),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12463E), Color(0xFF0A2622)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AdminColors.emerald500,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_hospital_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AURA',
                    style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.6)),
                Text('Medical · ICU',
                    style: TextStyle(
                        color: Color(0xFF9FE3BF), fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.current, required this.onSelect});

  final AdminTab current;
  final ValueChanged<AdminTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: AdminTab.values.map((tab) {
        final selected = tab == current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(tab),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AdminColors.emerald500.withOpacity(0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(tab.icon,
                        size: 19,
                        color: selected ? const Color(0xFF34D399) : const Color(0xFF7E9A90)),
                    const SizedBox(width: 12),
                    Text(tab.label,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? Colors.white : const Color(0xFFB4C7BF))),
                    if (selected) ...[
                      const Spacer(),
                      Container(width: 5, height: 5,
                          decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BottomProfile extends StatelessWidget {
  const _BottomProfile({
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;

  String get initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'A';
    return parts.length > 1
        ? parts[0][0] + parts[1][0]
        : parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.sidebarFooter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AdminColors.emerald500.withOpacity(0.2),
                child: Text(initials,
                    style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text(userEmail,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF7E9A90), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onSignOut,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AdminColors.rose.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 15, color: Color(0xFFFCA5A5)),
                  SizedBox(width: 6),
                  Text('Sign out',
                      style: TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}