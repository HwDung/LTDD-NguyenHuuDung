import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/lecturer_model.dart';
import 'package:nguyenhuudung/screens/crud/session_list_screen.dart';
import 'package:nguyenhuudung/screens/login_screen.dart';
import 'package:nguyenhuudung/screens/teacher/qr_display_attendance_screen.dart';
import 'package:nguyenhuudung/services/academic_service.dart';
import 'package:nguyenhuudung/services/auth_service.dart';
import 'package:nguyenhuudung/services/class_student_service.dart';
import 'package:nguyenhuudung/services/lecturer_service.dart';

class StaffDashboardScreen extends StatefulWidget {
  final VoidCallback? onSwitchRole;

  const StaffDashboardScreen({super.key, this.onSwitchRole});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _authService = AuthService();
  final _academicService = AcademicService();
  final _lecturerService = LecturerService();
  final _classStudentService = ClassStudentService();

  bool _isLoading = true;
  String? _username;
  String? _lecturerCode;
  LecturerModel? _currentLecturer;
  List<CourseClassModel> _allClasses = [];
  List<CourseClassModel> _myClasses = [];
  bool _showOnlyMyClasses = true;
  final Map<String, Map<String, int>> _attendanceSummaries = {};

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
      final lecturerCode = await _authService.getLecturerCode();
      final currentLecturer = lecturerCode != null ? await _lecturerService.findByCode(lecturerCode) : null;
      final classes = await _academicService.getCourseClasses().catchError((_) => <CourseClassModel>[]);

      final myFiltered = <CourseClassModel>[];
      final targetCode = (lecturerCode ?? '').trim().toUpperCase();
      final targetUuid = (currentLecturer?.id ?? '').trim().toLowerCase();
      final targetName = (currentLecturer?.fullName ?? username ?? '').trim().toLowerCase();

      for (final c in classes) {
        bool matched = false;

        // 1. So khớp theo mã giảng viên (GV001...)
        if (targetCode.isNotEmpty) {
          if (c.lecturerCode != null && c.lecturerCode!.trim().toUpperCase() == targetCode) {
            matched = true;
          } else if (c.lecturer?.lecturerCode != null && c.lecturer!.lecturerCode.trim().toUpperCase() == targetCode) {
            matched = true;
          } else if (c.lecturerId != null) {
            final lid = c.lecturerId!.trim().toUpperCase();
            if (lid == targetCode || lid.contains(targetCode)) {
              matched = true;
            }
          }
        }

        // 2. So khớp theo UUID giảng viên trong DB (userId từ Swagger API)
        if (!matched && targetUuid.isNotEmpty) {
          if (c.lecturerId != null && c.lecturerId!.trim().toLowerCase() == targetUuid) {
            matched = true;
          } else if (c.lecturer?.id != null && c.lecturer!.id.trim().toLowerCase() == targetUuid) {
            matched = true;
          }
        }

        // 3. So khớp theo Họ tên giảng viên
        if (!matched && targetName.isNotEmpty && targetName != 'giảng viên') {
          final cName = (c.lecturerName ?? c.displayLecturer).toLowerCase();
          if (cName.contains(targetName) || targetName.contains(cName)) {
            matched = true;
          }
        }

        if (matched) {
          myFiltered.add(c);
        }
      }

      final summaries = <String, Map<String, int>>{};
      for (final c in classes) {
        summaries[c.code] = await _classStudentService.getClassAttendanceSummary(c.code, sessionId: c.id?.toString());
      }

      if (!mounted) return;
      setState(() {
        _username = username ?? currentLecturer?.fullName ?? 'Giảng viên';
        _lecturerCode = lecturerCode ?? 'GV001';
        _currentLecturer = currentLecturer;
        _allClasses = classes;
        _myClasses = myFiltered;
        _attendanceSummaries.clear();
        _attendanceSummaries.addAll(summaries);
        // Nếu không có lớp nào lọc riêng được nhưng hệ thống có lớp, tự động mở xem tất cả lớp
        if (myFiltered.isEmpty && classes.isNotEmpty) {
          _showOnlyMyClasses = false;
        }
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

  List<CourseClassModel> get _displayedClasses =>
      _showOnlyMyClasses ? _myClasses : _allClasses;

  void _showSelectClassForQrSheet() {
    final list = _displayedClasses.isNotEmpty ? _displayedClasses : _allClasses;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn Lớp học để Tạo mã QR Điểm danh',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            ...list.map((c) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.qr_code_2, color: Colors.white),
              ),
              title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${c.semester} • GV: ${c.displayLecturer} • Sĩ số: ${c.capacity}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrDisplayAttendanceScreen(
                      sessionId: c.id?.toString() ?? '1',
                      courseClassCode: c.code,
                      sessionTitle: 'Lớp ${c.code} (${c.semester})',
                    ),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayed = _displayedClasses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Nhân viên / Giảng viên'),
        backgroundColor: Colors.teal,
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
            tooltip: 'Làm mới từ API',
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
                    Card(
                      elevation: 2,
                      color: Colors.teal.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.teal,
                              child: const Icon(Icons.badge, size: 36, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào, ${_username ?? "Giảng viên"}!',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'MÃ GV: ${_lecturerCode ?? "GV001"}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade700,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _currentLecturer?.department ?? 'GIẢNG VIÊN (STAFF)',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
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

                    // Card TẠO MÃ QR ĐIỂM DANH DÀNH CHO GIẢNG VIÊN
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.teal.shade800,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final targetList = displayed.isNotEmpty ? displayed : _allClasses;
                          if (targetList.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chưa có lớp học phần nào trong hệ thống.')),
                            );
                            return;
                          }
                          if (targetList.length == 1) {
                            final c = targetList.first;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QrDisplayAttendanceScreen(
                                  sessionId: c.id?.toString() ?? '1',
                                  courseClassCode: c.code,
                                  sessionTitle: 'Lớp ${c.code} (${c.semester})',
                                ),
                              ),
                            );
                          } else {
                            _showSelectClassForQrSheet();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.qr_code_2, color: Colors.teal, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Tạo mã QR Điểm danh Buổi học',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tạo mã QR chiếu lên máy chiếu cho sinh viên quét. Sinh viên quét mã -> quét mặt -> lấy vị trí để ghi nhận Có mặt.',
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

                    // Thanh lọc Lớp của tôi / Tất cả lớp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lớp học phần (${displayed.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_allClasses.isNotEmpty)
                          Row(
                            children: [
                              ChoiceChip(
                                label: Text('Lớp của tôi (${_myClasses.length})'),
                                selected: _showOnlyMyClasses,
                                onSelected: (val) {
                                  setState(() => _showOnlyMyClasses = true);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('Tất cả (${_allClasses.length})'),
                                selected: !_showOnlyMyClasses,
                                onSelected: (val) {
                                  setState(() => _showOnlyMyClasses = false);
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_showOnlyMyClasses && _myClasses.isEmpty && _allClasses.isNotEmpty)
                      Card(
                        color: Colors.amber.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.amber.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade900),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Chưa tìm thấy lớp được gán riêng cho mã "${_lecturerCode ?? "GV001"}". Bấm "Tất cả (${_allClasses.length})" phía trên để xem các lớp trong hệ thống.',
                                  style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (displayed.isEmpty)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Chưa có lớp học phần nào được phân công.'),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayed.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = displayed[index];
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
                                        item.code,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.semester,
                                          style: TextStyle(color: Colors.teal.shade900, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Giảng viên: ${item.displayLecturer}',
                                    style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sĩ số: ${item.capacity} sinh viên • Năm: ${item.academicYear}',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        (_attendanceSummaries[item.code]?['present'] ?? 0) > 0
                                            ? Icons.check_circle
                                            : Icons.people_outline,
                                        size: 16,
                                        color: (_attendanceSummaries[item.code]?['present'] ?? 0) > 0
                                            ? Colors.green
                                            : Colors.teal,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Điểm danh: ${_attendanceSummaries[item.code]?['present'] ?? 0} / ${_attendanceSummaries[item.code]?['total'] ?? 3} có mặt',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: (_attendanceSummaries[item.code]?['present'] ?? 0) > 0
                                              ? Colors.green.shade800
                                              : Colors.teal.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                                        icon: const Icon(Icons.qr_code_2, size: 18),
                                        label: const Text('Tạo QR Điểm danh'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => QrDisplayAttendanceScreen(
                                                sessionId: (item.id ?? 1).toString(),
                                                courseClassCode: item.code,
                                                sessionTitle: 'Lớp ${item.code} (${item.semester})',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                                        icon: const Icon(Icons.calendar_month, size: 18),
                                        label: const Text('Quản lý Buổi học'),
                                        onPressed: () {
                                          if (item.id != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => SessionListScreen(
                                                  courseClassId: item.id!,
                                                  courseClassName: item.code,
                                                ),
                                              ),
                                            );
                                          }
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
                  ],
                ),
              ),
            ),
    );
  }
}
