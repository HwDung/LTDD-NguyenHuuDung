import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/enrollment_model.dart';
import 'package:nguyenhuudung/models/subject_model.dart';
import 'package:nguyenhuudung/screens/crud/class_enrollment_management_screen.dart';
import 'package:nguyenhuudung/screens/crud/course_class_list_screen.dart';
import 'package:nguyenhuudung/screens/crud/lecturer_management_screen.dart';
import 'package:nguyenhuudung/screens/crud/student_management_screen.dart';
import 'package:nguyenhuudung/screens/crud/subject_list_screen.dart';
import 'package:nguyenhuudung/screens/login_screen.dart';
import 'package:nguyenhuudung/services/academic_service.dart';
import 'package:nguyenhuudung/services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onSwitchRole;

  const AdminDashboardScreen({super.key, this.onSwitchRole});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AuthService();
  final _academicService = AcademicService();

  bool _isLoading = true;
  String? _username;
  Map<String, dynamic>? _dashboardData;
  int _subjectCount = 0;
  int _classCount = 0;
  int _enrollmentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    try {
      final username = await _authService.getUsername();
      final results = await Future.wait([
        _academicService.getDashboard().catchError((_) => <String, dynamic>{}),
        _academicService.getSubjects().catchError((_) => <SubjectModel>[]),
        _academicService.getCourseClasses().catchError((_) => <CourseClassModel>[]),
        _academicService.getEnrollments().catchError((_) => <EnrollmentModel>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _username = username ?? 'Quản trị viên';
        _dashboardData = results[0] as Map<String, dynamic>;
        _subjectCount = (results[1] as List).length;
        _classCount = (results[2] as List).length;
        _enrollmentCount = (results[3] as List).length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Quản trị (Admin)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (widget.onSwitchRole != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Chuyển giao diện vai trò',
              onPressed: widget.onSwitchRole,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOverview,
            tooltip: 'Làm mới',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOverview,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Card(
                      elevation: 2,
                      color: Colors.indigo.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.indigo,
                              child: const Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào, ${_username ?? "Admin"}!',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'VAI TRÒ: QUẢN TRỊ VIÊN (ADMIN)',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card NỔI BẬT 1: THÊM SINH VIÊN VÀ GIẢNG VIÊN VÀO LỚP
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: Colors.indigo.shade800,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.group_add, color: Colors.indigo, size: 28),
                        ),
                        title: const Text(
                          'Thêm Sinh viên & Giảng viên vào Lớp',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Phân công giảng viên phụ trách và thêm sinh viên vào từng lớp học phần (phân lớp).',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClassEnrollmentManagementScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Card 2: Quản lý Sinh viên & Ảnh khuôn mặt
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.purple.shade100,
                          child: Icon(Icons.badge, color: Colors.purple.shade900, size: 26),
                        ),
                        title: const Text(
                          'Quản lý Sinh viên & Ảnh Khuôn mặt',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Thêm sinh viên, cấp mã MSSV & chụp/tải ảnh chân dung dùng đối soát điểm danh AI.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Card 3: Quản lý Giảng viên
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(Icons.school, color: Colors.teal.shade900, size: 26),
                        ),
                        title: const Text(
                          'Quản lý Giảng viên',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Thêm giảng viên, mã GV, họ tên, email, bộ môn và số điện thoại.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LecturerManagementScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Card 4: Quản lý Lớp học phần
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.meeting_room, color: Colors.orange.shade900, size: 26),
                        ),
                        title: const Text(
                          'Quản lý Lớp học phần (Course Classes)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Thêm lớp học phần mới, gán giảng viên, quản lý buổi học & sinh viên trong lớp.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CourseClassListScreen(readOnly: false)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Thống kê nhanh
                    Text(
                      'Thống kê tổng quan hệ thống',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard('Môn học', _subjectCount.toString(), Icons.menu_book, Colors.blue),
                        const SizedBox(width: 12),
                        _buildStatCard('Lớp học phần', _classCount.toString(), Icons.class_, Colors.orange),
                        const SizedBox(width: 12),
                        _buildStatCard('Đăng ký', _enrollmentCount.toString(), Icons.people_alt, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Danh mục học vụ khác',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    _buildManagementTile(
                      title: 'Danh sách Môn học (Subjects)',
                      subtitle: 'Xem và quản lý mã môn, số tín chỉ, môn tiên quyết',
                      icon: Icons.menu_book,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubjectListScreen(readOnly: false)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // API Dashboard data raw view
                    if (_dashboardData != null && _dashboardData!.isNotEmpty) ...[
                      ExpansionTile(
                        title: const Text('Dữ liệu từ API /api/dashboard'),
                        leading: const Icon(Icons.api),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(_dashboardData.toString()),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          radius: 24,
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
