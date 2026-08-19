import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../admin_colors.dart';
import 'admin_common.dart';

/// Top bar of the admin console — page title + live clock, alert bell and
/// profile menu. Mirrors the web `Navbar.tsx`.
class AdminNavbar extends StatefulWidget {
  const AdminNavbar({
    super.key,
    required this.title,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
    this.onMenuTap,
  });

  final String title;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;
  final VoidCallback? onMenuTap;

  @override
  State<AdminNavbar> createState() => _AdminNavbarState();
}

class _AdminNavbarState extends State<AdminNavbar> {
  final _alertItems = const [
    AlertItem(
      title: 'ICU Telemetry Alert',
      message: 'Vitals spike detected on ICU-101',
      severity: AlertSeverity.critical,
      time: '2 min ago',
    ),
    AlertItem(
      title: 'ER Patient Admitted',
      message: 'Liam Neeson admitted to ER-201',
      severity: AlertSeverity.info,
      time: '12 min ago',
    ),
    AlertItem(
      title: 'Lab Results Prepared',
      message: 'CBC panel ready for GEN-301',
      severity: AlertSeverity.success,
      time: '48 min ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0B2B26),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final showClock = w >= 640;
          final showEr = w >= 900;
          final showProfileText = w >= 640;
          return Row(
            children: [
              if (widget.onMenuTap != null) ...[
                IconButton(
                  onPressed: widget.onMenuTap,
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textMid),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text('Aura Medical Center Administration Console',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (showEr) ...[
                const _ErChip(),
                const SizedBox(width: 16),
              ],
              if (showClock) ...[
                const _ClockChip(),
                const SizedBox(width: 14),
              ],
              _BellButton(onTap: () => _showAlerts(context)),
              const SizedBox(width: 8),
              _ProfileChip(
                userName: widget.userName,
                userEmail: widget.userEmail,
                showText: showProfileText,
                onTap: () => _showProfile(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAlerts(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final menuWidth = (size.width - 32).clamp(240.0, 320.0);
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          size.width - menuWidth - 16, 72, 16, 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: menuWidth,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Notifications',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (final a in _alertItems) ...[
                    _AlertTile(item: a),
                    if (a != _alertItems.last)
                      const Divider(height: 1, color: AdminColors.border),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProfile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const menuWidth = 170.0;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          size.width - menuWidth - 16, 72, 16, 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: menuWidth,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.userName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  Text(widget.userEmail,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
        PopupMenuItem(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 16, color: AdminColors.rose),
              const SizedBox(width: 8),
              const Text('Sign out',
                  style: TextStyle(color: AdminColors.rose, fontSize: 13)),
            ],
          ),
          onTap: () async {
            Navigator.of(context).pop();
            final ok = await showAdminConfirm(context,
                title: 'Sign out?',
                message: 'You will be returned to the login screen.',
                confirmLabel: 'Sign out',
                danger: false);
            if (ok) widget.onSignOut();
          },
        ),
      ],
    );
  }
}

class _ErChip extends StatelessWidget {
  const _ErChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminColors.rose50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.rose100),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: AdminColors.rose),
          SizedBox(width: 6),
          Text('ER Capacity: 80%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AdminColors.rose)),
        ],
      ),
    );
  }
}

class _ClockChip extends StatelessWidget {
  const _ClockChip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = TimeOfDay.fromDateTime(now);
    final label = now.toLocal().weekday == 1
        ? 'Mon'
        : const [
            'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
          ][now.toLocal().weekday];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AdminColors.bgSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded,
              size: 14, color: AdminColors.emerald600),
          const SizedBox(width: 6),
          Text('$label · ${time.format(context)}',
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMid)),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded,
                color: AppColors.textMid, size: 22),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AdminColors.rose,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text('3',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        tooltip: 'Notifications',
      ),
    );
  }
}

enum AlertSeverity { critical, info, success }

class AlertItem {
  const AlertItem({
    required this.title,
    required this.message,
    required this.severity,
    required this.time,
  });

  final String title;
  final String message;
  final AlertSeverity severity;
  final String time;
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.item});

  final AlertItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.severity) {
      AlertSeverity.critical => AdminColors.rose,
      AlertSeverity.info => AdminColors.blue,
      AlertSeverity.success => AdminColors.teal,
    };
    final icon = switch (item.severity) {
      AlertSeverity.critical => Icons.sensors_rounded,
      AlertSeverity.info => Icons.person_add_alt_1_rounded,
      AlertSeverity.success => Icons.science_rounded,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ),
                    Text(item.time,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.message,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.userName,
    required this.userEmail,
    required this.onTap,
    this.showText = true,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onTap;
  final bool showText;

  String get initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'A';
    return parts.length > 1 ? parts[0][0] + parts[1][0] : parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(6, 5, showText ? 10 : 6, 5),
      decoration: BoxDecoration(
        color: AdminColors.bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            if (showText) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const Text('Administrator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}