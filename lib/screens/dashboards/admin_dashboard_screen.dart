import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/enrollment_model.dart';
import 'package:nguyenhuudung/models/lecturer_model.dart';
import 'package:nguyenhuudung/models/student_model.dart';
import 'package:nguyenhuudung/models/subject_model.dart';
import 'package:nguyenhuudung/screens/crud/class_enrollment_management_screen.dart';
import 'package:nguyenhuudung/screens/crud/course_class_list_screen.dart';
import 'package:nguyenhuudung/screens/crud/lecturer_management_screen.dart';
import 'package:nguyenhuudung/screens/crud/session_list_screen.dart';
import 'package:nguyenhuudung/screens/crud/student_management_screen.dart';
import 'package:nguyenhuudung/screens/crud/subject_list_screen.dart';
import 'package:nguyenhuudung/screens/login_screen.dart';
import 'package:nguyenhuudung/services/academic_service.dart';
import 'package:nguyenhuudung/services/auth_service.dart';
import 'package:nguyenhuudung/services/lecturer_service.dart';
import 'package:nguyenhuudung/services/student_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onSwitchRole;

  const AdminDashboardScreen({super.key, this.onSwitchRole});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AuthService();
  final _academicService = AcademicService();
  final _studentService = StudentService();
  final _lecturerService = LecturerService();

  bool _isLoading = true;
  String? _username;
  Map<String, dynamic>? _dashboardData;
  int _subjectCount = 0;
  int _classCount = 0;
  int _studentCount = 0;
  int _lecturerCount = 0;

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
        _studentService.getStudents().catchError((_) => <StudentModel>[]),
        _lecturerService.getLecturers().catchError((_) => <LecturerModel>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _username = username ?? 'Quản trị viên';
        _dashboardData = results[0] as Map<String, dynamic>;
        _subjectCount = (results[1] as List).length;
        _classCount = (results[2] as List).length;
        _studentCount = (results[4] as List).length;
        _lecturerCount = (results[5] as List).length;
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
                    const SizedBox(height: 16),

                    // Thống kê nhanh 4 mục
                    Text(
                      'Thống kê tổng quan hệ thống',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatCard('Sinh viên', _studentCount.toString(), Icons.badge, Colors.purple),
                        const SizedBox(width: 10),
                        _buildStatCard('Giảng viên', _lecturerCount.toString(), Icons.school, Colors.teal),
                        const SizedBox(width: 10),
                        _buildStatCard('Môn học', _subjectCount.toString(), Icons.menu_book, Colors.blue),
                        const SizedBox(width: 10),
                        _buildStatCard('Lớp học', _classCount.toString(), Icons.meeting_room, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Danh mục Quản lý Nghiệp vụ & Điểm danh',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // 1. Quản lý Sinh viên & Ảnh Khuôn mặt
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
                          'Thêm, sửa, xóa sinh viên; cấp mã MSSV & tải ảnh đối soát khuôn mặt.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
                          );
                          _loadOverview();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Quản lý Giảng viên
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
                          'Thêm, sửa, xóa giảng viên; mã GV, bộ môn, họ tên, email.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LecturerManagementScreen()),
                          );
                          _loadOverview();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Quản lý Môn học
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.menu_book, color: Colors.blue.shade900, size: 26),
                        ),
                        title: const Text(
                          'Quản lý Môn học (Subjects)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Thêm, sửa, xóa môn học; mã môn, số tín chỉ, mô tả môn học.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SubjectListScreen(readOnly: false)),
                          );
                          _loadOverview();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. Quản lý Lớp học phần
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
                          'Thêm, sửa, xóa lớp học phần; chỉ định giảng viên phụ trách & sĩ số.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CourseClassListScreen(readOnly: false)),
                          );
                          _loadOverview();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 5. Thêm Sinh viên & Giảng viên vào Lớp (Phân lớp)
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
                          'Phân lớp: Thêm SV & GV vào Lớp học',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Phân công giảng viên phụ trách và thêm sinh viên vào từng lớp học phần.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ClassEnrollmentManagementScreen()),
                          );
                          _loadOverview();
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 6. Quản lý Buổi học & Xem Bảng Điểm danh SQL Server
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.fact_check, color: Colors.green.shade900, size: 26),
                        ),
                        title: const Text(
                          'Buổi học & Bảng Điểm danh (AttendanceRecords)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Xem danh sách buổi học, mở/đóng điểm danh & đối soát dữ liệu điểm danh SQL Server.',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SessionListScreen(
                              courseClassId: 1,
                              courseClassName: '24D1INT10501 - Phát triển ứng dụng Web',
                              readOnly: false,
                            ),
                          ),
                        ),
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                count,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
