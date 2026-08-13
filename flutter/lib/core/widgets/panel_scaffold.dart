import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A labelled tab in a role dashboard sidebar.
class PanelTab {
  const PanelTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Responsive dashboard shell (fixed sidebar on desktop, drawer on mobile)
/// shared by the Receptionist, Patient and Sub-Admin panels. Mirrors the
/// existing Admin console layout so every role feels consistent.
class PanelScaffold extends StatelessWidget {
  const PanelScaffold({
    super.key,
    required this.sectionLabel,
    required this.tabs,
    required this.current,
    required this.userName,
    required this.userEmail,
    required this.roleLabel,
    required this.onSelect,
    required this.onSignOut,
    required this.body,
  });

  final String sectionLabel;
  final List<PanelTab> tabs;
  final int current;
  final String userName;
  final String userEmail;
  final String roleLabel;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        final sidebar = _Sidebar(
          sectionLabel: sectionLabel,
          tabs: tabs,
          current: current,
          userName: userName,
          userEmail: userEmail,
          roleLabel: roleLabel,
          onSelect: onSelect,
          onSignOut: onSignOut,
        );

        final content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(current), child: body),
        );

        if (!isDesktop) {
          final scaffoldKey = GlobalKey<ScaffoldState>();
          return Scaffold(
            key: scaffoldKey,
            drawer: SizedBox(width: 260, child: sidebar),
            body: Column(
              children: [
                _Navbar(
                  title: tabs[current].label,
                  userName: userName,
                  userEmail: userEmail,
                  roleLabel: roleLabel,
                  onSignOut: onSignOut,
                  onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F4),
          body: Row(
            children: [
              sidebar,
              Expanded(
                child: Column(
                  children: [
                    _Navbar(
                      title: tabs[current].label,
                      userName: userName,
                      userEmail: userEmail,
                      roleLabel: roleLabel,
                      onSignOut: onSignOut,
                    ),
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF1F5F4),
                        padding: const EdgeInsets.all(22),
                        child: content,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.sectionLabel,
    required this.tabs,
    required this.current,
    required this.userName,
    required this.userEmail,
    required this.roleLabel,
    required this.onSelect,
    required this.onSignOut,
  });

  final String sectionLabel;
  final List<PanelTab> tabs;
  final int current;
  final String userName;
  final String userEmail;
  final String roleLabel;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: const Color(0xFF0C1E1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              sectionLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0x8C10B981),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final selected = i == current;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelect(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0x2410B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab.icon,
                              size: 19,
                              color: selected
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF7E9A90),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFFB4C7BF),
                                ),
                              ),
                            ),
                            if (selected)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          _Footer(
            userName: userName,
            userEmail: userEmail,
            roleLabel: roleLabel,
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
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
              color: AppColors.emerald,
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
                Text(
                  'AURA',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.6,
                  ),
                ),
                Text(
                  'Medical · ICU',
                  style: TextStyle(color: Color(0xFF9FE3BF), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.userName,
    required this.userEmail,
    required this.roleLabel,
    required this.onSignOut,
  });

  final String userName;
  final String userEmail;
  final String roleLabel;
  final VoidCallback onSignOut;

  String get initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'A';
    return parts.length > 1 ? parts[0][0] + parts[1][0] : parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF071310),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.emerald.withValues(alpha: 0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      roleLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7E9A90),
                        fontSize: 11,
                      ),
                    ),
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
                color: const Color(0x1FF43F5E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 15, color: Color(0xFFFCA5A5)),
                  SizedBox(width: 6),
                  Text(
                    'Sign out',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Navbar extends StatelessWidget {
  const _Navbar({
    required this.title,
    required this.userName,
    required this.userEmail,
    required this.roleLabel,
    required this.onSignOut,
    this.onMenuTap,
  });

  final String title;
  final String userName;
  final String userEmail;
  final String roleLabel;
  final VoidCallback onSignOut;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8ECEB))),
      ),
      child: Row(
        children: [
          if (onMenuTap != null) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded, color: AppColors.textMid),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                builder: (sheetCtx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded,
                            color: Color(0xFFF43F5E)),
                        title: const Text('Sign out',
                            style: TextStyle(color: Color(0xFFF43F5E))),
                        onTap: () {
                          Navigator.of(sheetCtx).pop();
                          onSignOut();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded,
                      size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}