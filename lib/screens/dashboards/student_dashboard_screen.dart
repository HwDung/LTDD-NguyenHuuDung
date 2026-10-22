import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/subject_model.dart';
import 'package:nguyenhuudung/screens/login_screen.dart';
import 'package:nguyenhuudung/screens/student/student_attendance_flow_screen.dart';
import 'package:nguyenhuudung/services/academic_service.dart';
import 'package:nguyenhuudung/services/auth_service.dart';
import 'package:nguyenhuudung/services/class_student_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  final VoidCallback? onSwitchRole;

  const StudentDashboardScreen({super.key, this.onSwitchRole});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _authService = AuthService();
  final _academicService = AcademicService();
  final _classStudentService = ClassStudentService();

  bool _isLoading = true;
  String? _username;
  String _studentCode = 'SV000299';
  List<CourseClassModel> _myEnrolledClasses = [];
  List<CourseClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  final Map<String, bool> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    ClassStudentService.attendanceChangeNotifier.addListener(_onAttendanceChanged);
  }

  void _onAttendanceChanged() {
    if (mounted) _loadData();
  }

  @override
  void dispose() {
    ClassStudentService.attendanceChangeNotifier.removeListener(_onAttendanceChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final username = await _authService.getUsername();
      final code = await _authService.getStudentCode() ?? 'SV000299';

      final results = await Future.wait([
        _academicService.getCourseClasses().catchError((_) => <CourseClassModel>[]),
        _academicService.getSubjects().catchError((_) => <SubjectModel>[]),
        _classStudentService.getClassesForStudent(code),
      ]);

      final enrolled = results[2] as List<CourseClassModel>;
      final statusMap = <String, bool>{};
      for (final c in enrolled) {
        statusMap[c.code] = await _classStudentService.isStudentPresentInClass(c.code, code);
      }

      if (!mounted) return;
      setState(() {
        _studentCode = code;
        _username = username ?? 'Sinh viên $code';
        _classes = results[0] as List<CourseClassModel>;
        _subjects = results[1] as List<SubjectModel>;
        _myEnrolledClasses = enrolled;
        _attendanceStatus.clear();
        _attendanceStatus.addAll(statusMap);
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
        title: const Text('Dashboard Sinh viên'),
        backgroundColor: Colors.purple.shade700,
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
            onPressed: _loadData,
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
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card
                    Card(
                      elevation: 2,
                      color: Colors.purple.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.purple.shade700,
                              child: const Icon(Icons.school, size: 36, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào, ${_username ?? "Sinh viên"}!',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade700,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'MSSV: $_studentCode',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card Điểm danh thông minh NỔI BẬT
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.purple.shade800,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StudentAttendanceFlowScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.qr_code_scanner, color: Colors.purple.shade800, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Điểm danh lớp học ngay',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Quét QR từ giảng viên • So sánh gương mặt AI với ảnh mẫu • Lấy vị trí GPS',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Danh sách Lớp học phần sinh viên ĐÃ ĐƯỢC THÊM VÀO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lớp học phần của bạn (${_myEnrolledClasses.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'Đã ghi danh',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_myEnrolledClasses.isEmpty)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Bạn chưa được thêm vào lớp học nào. Hãy liên hệ Quản trị viên!'),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myEnrolledClasses.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = _myEnrolledClasses[index];
                          final isPresent = _attendanceStatus[c.code] ?? false;

                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        c.code,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${c.semester} - Năm ${c.academicYear}',
                                          style: TextStyle(color: Colors.purple.shade900, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.purple),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Giảng viên: ${c.displayLecturer}',
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        isPresent ? Icons.check_circle : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: isPresent ? Colors.green : Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isPresent ? 'Trạng thái: CÓ MẶT (Đã điểm danh)' : 'Trạng thái: Chưa điểm danh',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isPresent ? Colors.green.shade800 : Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: isPresent ? Colors.green.shade700 : Colors.purple.shade700,
                                        ),
                                        icon: Icon(isPresent ? Icons.verified : Icons.qr_code_scanner, size: 16),
                                        label: Text(isPresent ? 'Đã có mặt - Điểm danh lại' : 'Điểm danh lớp này'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => StudentAttendanceFlowScreen(
                                                initialClassCode: c.code,
                                                initialSessionId: c.id?.toString() ?? '1',
                                                initialSessionTitle: 'Lớp ${c.code} (${c.semester})',
                                              ),
                                            ),
                                          ).then((_) => _loadData());
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                    Text(
                      'Tất cả lớp học phần đang mở (${_classes.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _classes.length > 5 ? 5 : _classes.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final c = _classes[index];
                        return ListTile(
                          tileColor: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          leading: const Icon(Icons.class_outlined, color: Colors.purple),
                          title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('Học kỳ: ${c.semester} • Sĩ số tối đa: ${c.capacity}'),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Danh mục môn học (${_subjects.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subjects.length > 5 ? 5 : _subjects.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final s = _subjects[index];
                        return ListTile(
                          tileColor: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          leading: const Icon(Icons.check_circle_outline, color: Colors.purple),
                          title: Text('${s.code} - ${s.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('Số tín chỉ: ${s.credits}'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

