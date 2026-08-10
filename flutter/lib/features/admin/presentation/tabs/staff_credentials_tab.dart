import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../admin_colors.dart';
import '../widgets/admin_common.dart';

class StaffCredentialsTab extends StatefulWidget {
  const StaffCredentialsTab({
    super.key,
    required this.credentials,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<StaffCredential> credentials;
  final ValueChanged<StaffCredential> onAdd;
  final ValueChanged<StaffCredential> onUpdate;
  final ValueChanged<String> onDelete;

  @override
  State<StaffCredentialsTab> createState() => _StaffCredentialsTabState();
}

class _StaffCredentialsTabState extends State<StaffCredentialsTab> {
  late List<StaffCredential> _staff;
  String _search = '';
  String _roleFilter = 'all';
  String? _viewId;
  List<PermissionGroup> _permissionGroups = const [];

  final _cFullName = TextEditingController();
  final _cEmail = TextEditingController();
  final _cPhone = TextEditingController();
  String _cRole = 'doctor';
  String _cDepartment = '';
  final _cUsername = TextEditingController();
  List<String> _cPermissions = [];
  String? _cError;
  bool _creating = false;

  final _eFullName = TextEditingController();
  final _eEmail = TextEditingController();
  final _ePhone = TextEditingController();
  StaffCredential? _eCred;
  String _eDepartment = '';
  StaffStatus _eStatus = StaffStatus.active;
  List<String> _ePermissions = [];
  String? _eError;
  bool _saving = false;
  String? _deleteError;

  @override
  void initState() {
    super.initState();
    _staff = List.of(widget.credentials);
    _loadPermissions();
    _loadStaff();
  }

  @override
  void dispose() {
    _cFullName.dispose();
    _cEmail.dispose();
    _cPhone.dispose();
    _cUsername.dispose();
    _eFullName.dispose();
    _eEmail.dispose();
    _ePhone.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    try {
      final rows = await AdminRepository.listStaff();
      if (rows.isNotEmpty && mounted) setState(() => _staff = rows);
    } catch (_) {}
  }

  Future<void> _loadPermissions() async {
    try {
      final groups = await AdminRepository.getPermissions();
      if (groups.isNotEmpty && mounted) {
        setState(() => _permissionGroups = groups);
      }
    } catch (_) {}
  }

  int get _total => _staff.length;
  int get _doctors => _staff.where((c) => c.role == StaffRole.doctor).length;
  int get _receptionists =>
      _staff.where((c) => c.role == StaffRole.receptionist).length;
  int get _active => _staff.where((c) => c.status == StaffStatus.active).length;
  int get _suspended =>
      _staff.where((c) => c.status == StaffStatus.suspended).length;

  List<StaffCredential> get _filtered {
    return _staff.where((c) {
      final q = _search.toLowerCase();
      final okSearch = q.isEmpty ||
          c.fullName.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.employeeId.toLowerCase().contains(q);
      final okRole = _roleFilter == 'all' || c.role.name == _roleFilter;
      return okSearch && okRole;
    }).toList();
  }

  String _permissionLabel(String key) {
    for (final g in _permissionGroups) {
      for (final item in g.items) {
        if (item.key == key) return item.label;
      }
    }
    if (key == 'ALL') return 'Full Access';
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _deriveUsername(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9_.-]'), '');

  void _openCreate() {
    setState(() {
      _cFullName.clear();
      _cEmail.clear();
      _cPhone.clear();
      _cDepartment = '';
      _cUsername.clear();
      _cPermissions = [];
      _cRole = 'doctor';
      _cError = null;
    });
    showAdminModal(context,
        title: 'Create Staff Credential',
        subtitle: 'Generate login access for a doctor, sub-admin or receptionist',
        child: _buildCreateForm(context));
  }

  Widget _buildCreateForm(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModalField(
              label: 'Staff Role',
              field: Row(
                children: [
                  _roleTile(
                    role: 'doctor',
                    label: 'Doctor',
                    caption: 'Email invite',
                    icon: Icons.medical_services_rounded,
                    accent: AdminColors.blue,
                    onChanged: () => setLocal(() {}),
                  ),
                  const SizedBox(width: 10),
                  _roleTile(
                    role: 'subadmin',
                    label: 'Sub-admin',
                    caption: 'Permissions',
                    icon: Icons.admin_panel_settings_rounded,
                    accent: AdminColors.teal,
                    onChanged: () => setLocal(() {}),
                  ),
                  const SizedBox(width: 10),
                  _roleTile(
                    role: 'receptionist',
                    label: 'Receptionist',
                    caption: 'Generated password',
                    icon: Icons.assignment_rounded,
                    accent: AdminColors.purple,
                    onChanged: () => setLocal(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ModalField(
                    label: _cRole == 'doctor' ? 'Full Name (without Dr.)' : 'Full Name',
                    field: TextField(
                      controller: _cFullName,
                      onChanged: (v) => setLocal(() {
                        _cUsername.text = _deriveUsername(v);
                      }),
                      decoration: InputDecoration(
                        hintText: _cRole == 'doctor' ? 'e.g. Rajesh Kumar' : 'e.g. Priya Patel',
                        border: modalFieldBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModalField(
                    label: 'Email Address',
                    field: TextField(
                      controller: _cEmail,
                      decoration: InputDecoration(
                        hintText: 'name@auramedical.org',
                        border: modalFieldBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ModalField(
              label: 'Login Username (auto-generated from full name, editable)',
              field: TextField(
                controller: _cUsername,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AdminColors.emerald500),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              hint: 'The staff member signs in with this username (or their email) and the password they set via the emailed link.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ModalField(
                    label: 'Phone Number',
                    field: TextField(
                      controller: _cPhone,
                      decoration: InputDecoration(
                        hintText: '+91 98765 43210',
                        border: modalFieldBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
                if (_cRole != 'subadmin') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModalField(
                      label: 'Department',
                      field: DropdownButtonFormField<String>(
                        value: _cDepartment.isEmpty ? null : _cDepartment,
                        isExpanded: true,
                        hint: const Text('Select department', style: TextStyle(fontSize: 12)),
                        items: (departmentOptions[_cRole == 'receptionist' ? 'receptionist' : 'doctor'] ?? const <String>[])
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) => setLocal(() => _cDepartment = v ?? ''),
                        decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminColors.emerald500.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.emerald500.withOpacity(0.3)),
              ),
              child: Text(
                'A secure password-set link will be emailed to ${_cEmail.text.trim().isEmpty ? 'this $_cRole' : _cEmail.text.trim()}. '
                'The ${_cRole == 'doctor' ? 'doctor' : _cRole == 'receptionist' ? 'receptionist' : 'sub-admin'} uses the link to create their own password, then signs in to the '
                '${_cRole == 'doctor' ? 'Doctor' : _cRole == 'receptionist' ? 'Receptionist' : 'Admin'} Portal.',
                style: const TextStyle(fontSize: 11.5, height: 1.5, color: AppColors.textStrong),
              ),
            ),
            if (_cRole == 'subadmin') ...[
              const SizedBox(height: 16),
              Text('Permissions',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMid)),
              const SizedBox(height: 8),
              if (_permissionGroups.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminColors.bgSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: const Text('Loading available permissions…',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                )
              else
                _PermissionPicker(
                  groups: _permissionGroups,
                  selected: _cPermissions,
                  onChange: (v) => setLocal(() => _cPermissions = v),
                ),
              const SizedBox(height: 6),
              const Text('Select the modules this sub-admin can access. Leave empty to create an account with no module access.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
            if (_cError != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminColors.rose50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminColors.rose.withOpacity(0.3))),
                child: Text(_cError!, style: const TextStyle(fontSize: 12, color: AdminColors.rose, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AdminGhostButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminButton(
                    label: _creating ? 'Creating…' : 'Create & Activate',
                    onPressed: _creating ? null : () => _create(context),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _roleTile({
    required String role,
    required String label,
    required String caption,
    required IconData icon,
    required Color accent,
    VoidCallback? onChanged,
  }) {
    final selected = _cRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _cRole = role;
            _cDepartment = '';
            _cPermissions = [];
            _cError = null;
          });
          onChanged?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : AdminColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? accent : AppColors.textMuted),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? accent : AppColors.textBody)),
              Text(caption,
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final name = _cFullName.text.trim();
    final email = _cEmail.text.trim();
    if (name.isEmpty || email.isEmpty) {
      setState(() => _cError = 'Full name and email are required.');
      return;
    }
    setState(() {
      _creating = true;
      _cError = null;
    });
    try {
      final username = _cUsername.text.trim().isNotEmpty
          ? _cUsername.text.trim()
          : _deriveUsername(name);
      switch (_cRole) {
        case 'doctor':
          await AdminRepository.createDoctor({
            'user_name': username,
            'email': email,
            'phone': _cPhone.text.trim().isEmpty ? null : _cPhone.text.trim(),
            'department': _cDepartment.isEmpty ? null : _cDepartment,
          });
          break;
        case 'receptionist':
          await AdminRepository.createReceptionist({
            'user_name': username,
            'email': email,
          });
          break;
        case 'subadmin':
          await AdminRepository.createSubAdmin({
            'user_name': username,
            'email': email,
            'permissions': _cPermissions,
          });
          break;
        default:
          await AdminRepository.registerAdmin({
            'user_name': username,
            'email': email,
            'password': _generatePassword(),
          });
      }

      final now = DateTime.now();
      final prefix = _cRole == 'doctor'
          ? 'D'
          : _cRole == 'subadmin'
              ? 'S'
              : 'R';
      final empNum = 100 + now.millisecondsSinceEpoch % 900;
      final newCred = StaffCredential(
        id: 'CRED-$empNum',
        userId: null,
        adminId: _cRole == 'subadmin' ? empNum : null,
        fullName: _cRole == 'doctor' ? 'Dr. $name' : name,
        role: _staffRoleFromLabel(_cRole),
        email: email,
        phone: _cPhone.text.trim().isEmpty ? '+91 00000 00000' : _cPhone.text.trim(),
        department: _cDepartment.isEmpty
            ? (_cRole == 'doctor'
                ? 'General Medicine'
                : _cRole == 'receptionist'
                    ? 'Front Desk - OPD'
                    : 'Administration')
            : _cDepartment,
        employeeId: 'EMP-$prefix$empNum',
        status: StaffStatus.active,
        createdAt: now.toIso8601String().split('T').first,
        lastLogin: null,
        permissions: _cRole == 'subadmin' ? _cPermissions : [],
      );
      setState(() => _staff = [newCred, ..._staff]);
      widget.onAdd(newCred);
      Navigator.of(context).pop();
      showAdminToast(context, '${capitalize(_cRole)} account created — password email sent to $email.');
    } catch (e) {
      setState(() => _cError = e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  static final _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#\$!';
  String _generatePassword() {
    final b = StringBuffer();
    for (var i = 0; i < 12; i++) {
      b.write(_chars[DateTime.now().millisecondsSinceEpoch % _chars.length]);
    }
    return b.toString();
  }

  Future<void> _toggleStatus(StaffCredential cred) async {
    final next = cred.status == StaffStatus.active
        ? StaffStatus.suspended
        : StaffStatus.active;
    if (cred.userId != null) {
      try {
        await AdminRepository.updateStaff(cred.userId!, {'status': next.name.toUpperCase()});
      } catch (e) {
        showAdminToast(context, 'Failed to update status: $e');
        return;
      }
    }
    final updated = cred.copyWith(status: next);
    setState(() => _staff = _staff.map((c) => c.id == cred.id ? updated : c).toList());
    widget.onUpdate(updated);
    showAdminToast(context, next == StaffStatus.active ? 'Account activated.' : 'Account suspended.');
  }

  void _openEdit(StaffCredential cred) {
    setState(() {
      _eCred = cred;
      _eFullName.text = cred.fullName.replaceFirst(RegExp(r'^Dr\.\s*', caseSensitive: false), '');
      _eEmail.text = cred.email == '—' ? '' : cred.email;
      _ePhone.text = cred.phone == '—' ? '' : cred.phone;
      _eDepartment = cred.department;
      _eStatus = cred.status;
      _ePermissions = cred.permissions;
      _eError = null;
    });
    showAdminModal(context,
        title: 'Edit Credential',
        subtitle: 'Update ${cred.fullName} (${_roleLabel(cred.role)})',
        child: _buildEditForm(context));
  }

  Widget _buildEditForm(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ModalField(
                    label: _eCred?.role == StaffRole.doctor ? 'Full Name (without Dr.)' : 'Full Name',
                    field: TextField(
                      controller: _eFullName,
                      decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModalField(
                    label: 'Email Address',
                    field: TextField(
                      controller: _eEmail,
                      decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ModalField(
                    label: 'Phone Number',
                    field: TextField(
                      controller: _ePhone,
                      decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModalField(
                    label: 'Status',
                    field: DropdownButtonFormField<String>(
                      value: _eStatus.name,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (v) => setLocal(() => _eStatus = staffStatusFromLabel(v ?? 'active')),
                      decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                  ),
                ),
              ],
            ),
            if (_eCred?.role == StaffRole.doctor || _eCred?.role == StaffRole.receptionist) ...[
              const SizedBox(height: 14),
              ModalField(
                label: 'Department',
                field: DropdownButtonFormField<String>(
                  value: _eDepartment.isEmpty ? null : _eDepartment,
                  isExpanded: true,
                  hint: const Text('Select department', style: TextStyle(fontSize: 12)),
                  items: (departmentOptions[_eCred!.role.name] ?? <String>[])
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setLocal(() => _eDepartment = v ?? ''),
                  decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
            ],
            if (_eCred?.role == StaffRole.subadmin) ...[
              const SizedBox(height: 16),
              Text('Permissions',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMid)),
              const SizedBox(height: 8),
              if (_permissionGroups.isNotEmpty)
                _PermissionPicker(
                  groups: _permissionGroups,
                  selected: _ePermissions,
                  onChange: (v) => setLocal(() => _ePermissions = v),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminColors.bgSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: const Text('Loading available permissions…',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ),
            ],
            if (_eCred?.userId == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminColors.amber50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminColors.ambery.withOpacity(0.4)),
                ),
                child: const Text('This record is from demo data and is not saved in the database yet.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600)),
              ),
            ],
            if (_eError != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminColors.rose50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminColors.rose.withOpacity(0.3))),
                child: Text(_eError!, style: const TextStyle(fontSize: 12, color: AdminColors.rose, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AdminGhostButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminButton(
                    label: _saving ? 'Saving…' : 'Save Changes',
                    onPressed: _saving ? null : () => _saveEdit(context),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveEdit(BuildContext context) async {
    final cred = _eCred;
    if (cred == null) return;
    setState(() {
      _saving = true;
      _eError = null;
    });
    try {
      if (cred.userId != null) {
        await AdminRepository.updateStaff(cred.userId!, {
          'user_name': _deriveUsername(_eFullName.text.trim()),
          'email': _eEmail.text.trim(),
          'phone': cred.role == StaffRole.doctor && _ePhone.text.trim().isNotEmpty ? _ePhone.text.trim() : null,
          'department': cred.role == StaffRole.doctor ? _eDepartment : null,
          'status': _eStatus.name.toUpperCase(),
        });
        if (cred.role == StaffRole.subadmin && cred.adminId != null) {
          await AdminRepository.updatePermissions({
            'admin_id': cred.adminId,
            'permissions': _ePermissions,
          });
        }
      }
      final updated = cred.copyWith(
        fullName: cred.role == StaffRole.doctor ? 'Dr. ${_eFullName.text.trim()}' : _eFullName.text.trim(),
        email: _eEmail.text.trim(),
        phone: _ePhone.text.trim().isEmpty ? '—' : _ePhone.text.trim(),
        department: _eDepartment,
        status: _eStatus,
        permissions: cred.role == StaffRole.subadmin ? _ePermissions : cred.permissions,
      );
      setState(() => _staff = _staff.map((c) => c.id == cred.id ? updated : c).toList());
      widget.onUpdate(updated);
      Navigator.of(context).pop();
      showAdminToast(context, 'Credential updated successfully.');
    } catch (e) {
      setState(() => _eError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openDelete(StaffCredential cred) {
    showAdminConfirm(
      context,
      title: 'Delete credential?',
      message:
          'This will permanently delete the account for ${cred.fullName} (${_roleLabel(cred.role)} — ${cred.email}). '
          'The user will immediately lose access and this cannot be undone.',
      confirmLabel: 'Delete Permanently',
    ).then((ok) async {
      if (!ok || !mounted) return;
      try {
        if (cred.userId != null) {
          await AdminRepository.deleteStaff(cred.userId!);
        } else {
          _deleteError = 'This record is not linked to a backend account, so it cannot be permanently deleted.';
        }
        if (_deleteError == null) {
          setState(() => _staff = _staff.where((c) => c.id != cred.id).toList());
          widget.onDelete(cred.id);
          showAdminToast(context, 'Credential deleted — ${cred.fullName} (${_roleLabel(cred.role)}) has been permanently deleted.');
        } else {
          showAdminToast(context, _deleteError!);
        }
      } catch (e) {
        showAdminToast(context, 'Failed to delete credential: $e');
      } finally {
        setState(() {
          _deleteError = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(2),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 1200
                ? 4
                : constraints.maxWidth >= 700
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
            final cards = [
              KpiCard(
                label: 'Total Staff Accounts',
                value: '$_total',
                sub: '$_active active credentials',
                icon: Icons.key_rounded,
              ),
              KpiCard(
                label: 'Doctor Logins',
                value: '$_doctors',
                sub: 'Physician portal access',
                icon: Icons.medical_services_rounded,
                iconBg: AdminColors.blue50,
                iconColor: AdminColors.blue,
              ),
              KpiCard(
                label: 'Receptionist Logins',
                value: '$_receptionists',
                sub: 'Front desk access',
                icon: Icons.assignment_rounded,
                iconBg: AdminColors.purple50,
                iconColor: AdminColors.purple,
              ),
              KpiCard(
                label: 'Suspended',
                value: '$_suspended',
                sub: 'Credentials on hold',
                icon: Icons.gpp_bad_rounded,
                iconBg: AdminColors.amber50,
                iconColor: const Color(0xFFD97706),
              ),
            ];
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < cards.length; i++)
                  SizedBox(width: width, child: cards[i]),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _filterBar(),
        const SizedBox(height: 20),
        _StaffTable(
          staff: _filtered,
          viewId: _viewId,
          permissionLabel: _permissionLabel,
          onToggleView: (id) => setState(() => _viewId = _viewId == id ? null : id),
          onToggleStatus: _toggleStatus,
          onEdit: _openEdit,
          onDelete: _openDelete,
        ),
      ],
    );
  }

  Widget _filterBar() {
    return AdminCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final search = AdminSearchField(
            hint: 'Search by name, email, employee ID…',
            value: _search,
            onChanged: (v) => setState(() => _search = v),
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedFilter(
                options: ['all', 'doctor', 'receptionist', 'subadmin', 'admin'],
                selected: _roleFilter,
                onChanged: (v) => setState(() => _roleFilter = v),
              ),
              AdminButton(
                label: 'Create Credential',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: _openCreate,
              ),
            ],
          );
          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 320, child: search),
                const Spacer(),
                actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 12), actions],
          );
        },
      ),
    );
  }
}

const departmentOptions = <String, List<String>>{
  'doctor': [
    'General Medicine',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Maternity',
    'Dermatology',
    'ENT',
    'Ophthalmology',
    'Psychiatry',
  ],
  'receptionist': [
    'Front Desk - OPD',
    'Front Desk - Emergency',
    'Front Desk - Maternity',
    'Front Desk - Pediatrics',
    'Billing Counter',
    'Insurance & Claims',
  ],
};

String _roleLabel(StaffRole r) => switch (r) {
      StaffRole.doctor => 'doctor',
      StaffRole.receptionist => 'receptionist',
      StaffRole.subadmin => 'sub-admin',
      StaffRole.admin => 'admin',
    };

StaffRole _staffRoleFromLabel(String label) => switch (label) {
      'receptionist' => StaffRole.receptionist,
      'subadmin' => StaffRole.subadmin,
      'admin' => StaffRole.admin,
      _ => StaffRole.doctor,
    };

StaffStatus staffStatusFromLabel(String label) => switch (label) {
      'active' => StaffStatus.active,
      'suspended' => StaffStatus.suspended,
      _ => StaffStatus.inactive,
    };

(Color, Color, IconData) _roleMeta(StaffRole r) => switch (r) {
      StaffRole.doctor => (AdminColors.blue50, AdminColors.blue, Icons.medical_services_rounded),
      StaffRole.receptionist => (AdminColors.purple50, AdminColors.purple, Icons.assignment_rounded),
      StaffRole.subadmin => (AdminColors.teal50, AdminColors.teal, Icons.admin_panel_settings_rounded),
      StaffRole.admin => (AdminColors.bgSubtle, AppColors.textStrong, Icons.shield_rounded),
    };

(Color, Color) _staffStatusColors(StaffStatus s) => switch (s) {
      StaffStatus.active => (AdminColors.emerald500.withOpacity(0.08), AdminColors.emerald700),
      StaffStatus.suspended => (AdminColors.amber50, const Color(0xFFD97706)),
      StaffStatus.inactive => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };

class _StaffTable extends StatelessWidget {
  const _StaffTable({
    required this.staff,
    required this.viewId,
    required this.permissionLabel,
    required this.onToggleView,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final List<StaffCredential> staff;
  final String? viewId;
  final String Function(String key) permissionLabel;
  final ValueChanged<String> onToggleView;
  final ValueChanged<StaffCredential> onToggleStatus;
  final ValueChanged<StaffCredential> onEdit;
  final ValueChanged<StaffCredential> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < staff.length; i++) ...[
          _StaffRow(
            cred: staff[i],
            expanded: viewId == staff[i].id,
            permissionLabel: permissionLabel,
            onToggleView: () => onToggleView(staff[i].id),
            onToggleStatus: () => onToggleStatus(staff[i]),
            onEdit: () => onEdit(staff[i]),
            onDelete: () => onDelete(staff[i]),
          ),
          if (i != staff.length - 1) const SizedBox(height: 4),
        ],
        if (staff.isEmpty)
          const AdminEmpty(message: 'No staff credentials found'),
      ],
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.cred,
    required this.expanded,
    required this.permissionLabel,
    required this.onToggleView,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final StaffCredential cred;
  final bool expanded;
  final String Function(String key) permissionLabel;
  final VoidCallback onToggleView;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (roleBg, roleFg, roleIcon) = _roleMeta(cred.role);
    final (statusBg, statusFg) = _staffStatusColors(cred.status);
    final opacity = cred.status == StaffStatus.inactive ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final nameId = Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: roleBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(roleIcon, size: 18, color: roleFg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cred.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                          Text(cred.employeeId,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                );

                final rolePill = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: roleFg.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 12, color: roleFg),
                      const SizedBox(width: 4),
                      Text(_roleLabel(cred.role).toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: roleFg, letterSpacing: 0.5)),
                    ],
                  ),
                );

                final contact = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(cred.email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMid)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(cred.phone,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textBody)),
                        ),
                      ],
                    ),
                  ],
                );

                final dept = Row(
                  children: [
                    const Icon(Icons.apartment_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(cred.department,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMid)),
                    ),
                  ],
                );

                final statusPill = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: statusFg.withOpacity(0.25))),
                  child: Text(capitalize(cred.status.name),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusFg)),
                );

                final actions = Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (cred.status != StaffStatus.inactive)
                      _miniAction(
                        label: cred.status == StaffStatus.active ? 'Suspend' : 'Activate',
                        bg: cred.status == StaffStatus.active ? AdminColors.amber50 : AdminColors.emerald500.withOpacity(0.08),
                        fg: cred.status == StaffStatus.active ? const Color(0xFFD97706) : AdminColors.emerald700,
                        onTap: onToggleStatus,
                      ),
                    _miniAction(label: 'Edit', bg: AdminColors.bgSubtle, fg: AppColors.textStrong, onTap: onEdit),
                    _miniAction(label: 'Delete', bg: AdminColors.rose50, fg: AdminColors.rose, onTap: onDelete),
                    _miniAction(label: 'Details', bg: AdminColors.bgSubtle, fg: AppColors.textStrong, onTap: onToggleView),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      SizedBox(width: 240, child: nameId),
                      SizedBox(width: 110, child: rolePill),
                      Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: contact)),
                      Expanded(child: dept),
                      SizedBox(width: 90, child: statusPill),
                      SizedBox(width: 260, child: Align(alignment: Alignment.centerRight, child: actions)),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: nameId),
                        rolePill,
                      ],
                    ),
                    const SizedBox(height: 10),
                    contact,
                    const SizedBox(height: 8),
                    dept,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        statusPill,
                        const Spacer(),
                        actions,
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (expanded) _StaffDetails(cred: cred, permissionLabel: permissionLabel),
        ],
      ),
    );
  }

  Widget _miniAction({
    required String label,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

class _StaffDetails extends StatelessWidget {
  const _StaffDetails({required this.cred, required this.permissionLabel});

  final StaffCredential cred;
  final String Function(String key) permissionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.bgSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final items = [
                _detail('Employee ID', cred.employeeId),
                _detail('Account Created', cred.createdAt),
                _detail('Last Login', cred.lastLogin ?? 'Never logged in'),
                _detail('Login Portal', _portalFor(cred.role)),
              ];
              if (isWide) {
                return Row(
                  children: [
                    for (final it in items) Expanded(child: it),
                  ],
                );
              }
              return Wrap(
                spacing: 24,
                runSpacing: 14,
                children: [for (final it in items) SizedBox(width: 140, child: it)],
              );
            },
          ),
          if (cred.role == StaffRole.subadmin) ...[
            const Divider(height: 24, color: AdminColors.border),
            const Text('ASSIGNED PERMISSIONS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            if (cred.permissions.isEmpty)
              const Text('No module permissions assigned.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cred.permissions.map((p) {
                  final full = p == 'ALL';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: full ? AdminColors.teal50 : AdminColors.bgSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: full ? AdminColors.teal100 : AdminColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(full ? Icons.shield_rounded : Icons.remove_circle_outline_rounded, size: 12, color: full ? AdminColors.teal : AppColors.textStrong),
                        const SizedBox(width: 5),
                        Text(full ? 'Full Access' : permissionLabel(p),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: full ? AdminColors.teal : AppColors.textStrong)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  String _portalFor(StaffRole r) => switch (r) {
        StaffRole.doctor => 'Doctor Portal',
        StaffRole.receptionist => 'Reception Desk',
        _ => 'Admin Console',
      };

  Widget _detail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ],
    );
  }
}

class _PermissionPicker extends StatelessWidget {
  const _PermissionPicker({
    required this.groups,
    required this.selected,
    required this.onChange,
  });

  final List<PermissionGroup> groups;
  final List<String> selected;
  final ValueChanged<List<String>> onChange;

  @override
  Widget build(BuildContext context) {
    final allKeys = groups.expand((g) => g.items.map((i) => i.key)).toList();
    final isFull = selected.contains('ALL');

    void toggle(String key) {
      if (key == 'ALL') {
        onChange(isFull ? [] : ['ALL']);
        return;
      }
      final withoutAll = selected.where((p) => p != 'ALL').toList();
      onChange(withoutAll.contains(key)
          ? withoutAll.where((p) => p != key).toList()
          : [...withoutAll, key]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('CHOOSE ACCESS OPTIONS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.textMuted)),
            ),
            GestureDetector(
              onTap: () => onChange(isFull ? [] : allKeys),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AdminColors.teal50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminColors.teal100)),
                child: Text(isFull ? 'Clear all' : 'Select all',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.teal)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final group in groups) ...[
          Text(group.group,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.items.map((opt) {
              final checked = selected.contains(opt.key);
              return GestureDetector(
                onTap: () => toggle(opt.key),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 120) / 2,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: checked ? AdminColors.teal50.withOpacity(0.7) : Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: checked ? AdminColors.teal : AdminColors.border,
                      width: checked ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 17,
                        color: checked ? AdminColors.teal : AppColors.textMuted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.label,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: checked ? AdminColors.teal : AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text(opt.description,
                                style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}