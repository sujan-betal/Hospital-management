import 'package:flutter/material.dart';

import '../doctor_colors.dart';

enum DoctorTab {
  schedule('My Schedule', Icons.calendar_month_rounded),
  prescriptions('Prescriptions', Icons.description_rounded),
  labOrders('Lab Orders', Icons.science_rounded),
  consultations('Consultations', Icons.video_call_rounded),
  earnings('Earnings & Payout', Icons.account_balance_rounded);

  const DoctorTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

class DoctorSidebar extends StatelessWidget {
  const DoctorSidebar({
    super.key,
    required this.current,
    required this.userName,
    required this.userRole,
    required this.onSelect,
    required this.onSignOut,
  });

  final DoctorTab current;
  final String userName;
  final String userRole;
  final ValueChanged<DoctorTab> onSelect;
  final VoidCallback onSignOut;

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'D';
    return parts.length > 1
        ? parts[0][0] + parts[1][0]
        : parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      color: DoctorColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Brand(),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'CLINICAL CONSOLE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: DoctorColors.textBody,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _Menu(current: current, onSelect: onSelect)),
          _BottomProfile(
            userName: userName,
            userRole: userRole,
            initials: _initials,
            onSignOut: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
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
        border: Border.all(color: DoctorColors.borderAccent),
      ),
      child: const Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: DoctorColors.emerald,
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
                Text('AURA Medical',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('DOCTOR PORTAL',
                    style: TextStyle(
                        color: DoctorColors.emeraldLight,
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

  final DoctorTab current;
  final ValueChanged<DoctorTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: DoctorTab.values.map((tab) {
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
                  color: selected ? DoctorColors.emerald : Colors.transparent,
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
                    Text(tab.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF8AA098),
                        )),
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
    required this.userRole,
    required this.initials,
    required this.onSignOut,
  });

  final String userName;
  final String userRole;
  final String initials;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DoctorColors.surfaceDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorColors.border),
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
                    colors: [DoctorColors.emerald, Color(0xFF12463E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DoctorColors.borderAccent),
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
                    Text(userName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(userRole,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: DoctorColors.emeraldLight, fontSize: 10)),
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
                  border: Border.all(color: DoctorColors.rose.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 15, color: DoctorColors.rose),
                    SizedBox(width: 7),
                    Text('Exit Dashboard',
                        style: TextStyle(
                            color: DoctorColors.rose,
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
