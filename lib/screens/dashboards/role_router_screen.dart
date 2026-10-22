import 'package:flutter/material.dart';
import 'package:nguyenhuudung/core/token_storage.dart';
import 'package:nguyenhuudung/screens/dashboards/admin_dashboard_screen.dart';
import 'package:nguyenhuudung/screens/dashboards/staff_dashboard_screen.dart';
import 'package:nguyenhuudung/screens/dashboards/student_dashboard_screen.dart';

class RoleRouterScreen extends StatefulWidget {
  final String? initialRole;

  const RoleRouterScreen({super.key, this.initialRole});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  final _tokenStorage = TokenStorage();
  String _currentRole = 'Admin';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineRole();
  }

  Future<void> _determineRole() async {
    if (widget.initialRole != null && widget.initialRole!.isNotEmpty) {
      setState(() {
        _currentRole = _normalizeRole(widget.initialRole!);
        _isLoading = false;
      });
      return;
    }

    final storedRole = await _tokenStorage.getRole();
    if (!mounted) return;
    setState(() {
      _currentRole = _normalizeRole(storedRole ?? 'Admin');
      _isLoading = false;
    });
  }

  String _normalizeRole(String role) {
    final lower = role.toLowerCase();
    if (lower.contains('admin') || lower.contains('quản trị')) {
      return 'Admin';
    } else if (lower.contains('lecturer') ||
        lower.contains('staff') ||
        lower.contains('teacher') ||
        lower.contains('giảng viên') ||
        lower.contains('nhân viên')) {
      return 'Staff';
    } else {
      return 'Student';
    }
  }

  void _showRoleSwitcherSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chuyển đổi giao diện vai trò (Role Preview):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dành cho chấm thi & kiểm thử giao diện các quyền người dùng:',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                title: const Text('1. Quản trị viên (Admin)'),
                subtitle: const Text('Vào trang quản trị, CRUD môn học, lớp, đăng ký, thống kê'),
                trailing: _currentRole == 'Admin' ? const Icon(Icons.check_circle, color: Colors.indigo) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentRole = 'Admin');
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.badge, color: Colors.white),
                ),
                title: const Text('2. Nhân viên / Giảng viên (Staff / Lecturer)'),
                subtitle: const Text('Dashboard nhân viên phụ trách lớp học phần & điểm danh sinh viên'),
                trailing: _currentRole == 'Staff' ? const Icon(Icons.check_circle, color: Colors.teal) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentRole = 'Staff');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade700,
                  child: const Icon(Icons.school, color: Colors.white),
                ),
                title: const Text('3. Sinh viên / Khách hàng (Student / Customer)'),
                subtitle: const Text('Dashboard sinh viên xem lịch học, lớp đăng ký & điểm danh'),
                trailing: _currentRole == 'Student' ? const Icon(Icons.check_circle, color: Colors.purple) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentRole = 'Student');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_currentRole) {
      case 'Staff':
        return StaffDashboardScreen(onSwitchRole: _showRoleSwitcherSheet);
      case 'Student':
        return StudentDashboardScreen(onSwitchRole: _showRoleSwitcherSheet);
      case 'Admin':
      default:
        return AdminDashboardScreen(onSwitchRole: _showRoleSwitcherSheet);
    }
  }
}
