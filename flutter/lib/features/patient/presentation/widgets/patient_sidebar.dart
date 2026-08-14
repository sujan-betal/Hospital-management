import 'package:flutter/material.dart';

import '../patient_colors.dart';

enum PatientTab {
  records('My Appointments & Bills', Icons.event_note_rounded),
  book('Book Appointment', Icons.medical_services_rounded),
  profile('Profile Details', Icons.person_rounded);

  const PatientTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class PatientSidebar extends StatelessWidget {
  const PatientSidebar({
    super.key,
    required this.current,
    required this.userName,
    required this.userPhone,
    required this.onSelect,
    required this.onSignOut,
  });

  final PatientTab current;
  final String userName;
  final String userPhone;
  final ValueChanged<PatientTab> onSelect;
  final VoidCallback onSignOut;

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'PT';
    if (parts.length > 1) return parts[0][0] + parts[1][0];
    return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      color: PatientColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'MY HEALTH DASHBOARD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: PatientColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _Menu(current: current, onSelect: onSelect)),
          _BottomProfile(
            userName: userName,
            userPhone: userPhone,
            initials: _initials,
            onSignOut: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12463E), Color(0xFF0A2622)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PatientColors.sidebarAccent),
      ),
      child: const Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: PatientColors.emerald,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AURA Care',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('PATIENT PORTAL',
                    style: TextStyle(
                        color: PatientColors.emeraldLight,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2)),
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

  final PatientTab current;
  final ValueChanged<PatientTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: PatientTab.values.map((tab) {
        final selected = tab == current;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(tab),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? PatientColors.emerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(tab.icon,
                        size: 20,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF5C7D73)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(tab.label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF8AA098),
                          )),
                    ),
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
    required this.userPhone,
    required this.initials,
    required this.onSignOut,
  });

  final String userName;
  final String userPhone;
  final String initials;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PatientColors.sidebarDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.sidebarBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [PatientColors.emerald, Color(0xFF12463E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PatientColors.sidebarAccent),
                ),
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName.isEmpty ? 'New Patient' : userName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(userPhone.isEmpty ? 'Logged in via OTP' : userPhone,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: PatientColors.emeraldLight, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSignOut,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PatientColors.rose.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 15, color: PatientColors.rose),
                    SizedBox(width: 7),
                    Text('Exit Dashboard',
                        style: TextStyle(
                            color: PatientColors.rose,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
