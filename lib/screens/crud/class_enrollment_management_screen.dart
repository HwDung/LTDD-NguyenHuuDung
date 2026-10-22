import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/lecturer_model.dart';
import 'package:nguyenhuudung/models/student_model.dart';
import 'package:nguyenhuudung/services/academic_service.dart';
import 'package:nguyenhuudung/services/class_student_service.dart';
import 'package:nguyenhuudung/services/lecturer_service.dart';
import 'package:nguyenhuudung/services/student_service.dart';

class ClassEnrollmentManagementScreen extends StatefulWidget {
  final int? initialClassId;
  final String? initialClassCode;

  const ClassEnrollmentManagementScreen({
    super.key,
    this.initialClassId,
    this.initialClassCode,
  });

  @override
  State<ClassEnrollmentManagementScreen> createState() => _ClassEnrollmentManagementScreenState();
}

class _ClassEnrollmentManagementScreenState extends State<ClassEnrollmentManagementScreen> {
  final _academicService = AcademicService();
  final _lecturerService = LecturerService();
  final _studentService = StudentService();
  final _classStudentService = ClassStudentService();

  List<CourseClassModel> _classes = [];
  List<LecturerModel> _lecturers = [];
  List<StudentModel> _allStudents = [];

  CourseClassModel? _selectedClass;
  List<StudentModel> _enrolledStudents = [];
  String? _selectedLecturerName;

  bool _isLoading = true;
  bool _isSavingLecturer = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _academicService.getCourseClasses().catchError((_) => <CourseClassModel>[]),
        _lecturerService.getLecturers(),
        _studentService.getStudents(),
      ]);

      var classes = results[0] as List<CourseClassModel>;
      if (classes.isEmpty) {
        classes = [
          CourseClassModel(
            id: 1,
            code: 'COMP101_01',
            subjectId: 1,
            semester: 'Học kỳ 1 - 2026',
            academicYear: 2026,
            capacity: 50,
            lecturerId: 'gv-001',
            lecturerCode: 'GV001',
            lecturerName: 'ThS. Trần Văn Hùng',
          ),
          CourseClassModel(
            id: 2,
            code: 'IT202_01',
            subjectId: 2,
            semester: 'Học kỳ 1 - 2026',
            academicYear: 2026,
            capacity: 45,
            lecturerId: 'gv-002',
            lecturerCode: 'GV002',
            lecturerName: 'TS. Nguyễn Thị Lan',
          ),
        ];
      }

      final lecturers = results[1] as List<LecturerModel>;
      final allStudents = results[2] as List<StudentModel>;

      // Chọn lớp ban đầu
      CourseClassModel? defaultClass;
      if (widget.initialClassId != null) {
        defaultClass = classes.firstWhere((c) => c.id == widget.initialClassId, orElse: () => classes.first);
      } else if (widget.initialClassCode != null) {
        defaultClass = classes.firstWhere((c) => c.code == widget.initialClassCode, orElse: () => classes.first);
      } else if (classes.isNotEmpty) {
        defaultClass = classes.first;
      }

      _classes = classes;
      _lecturers = lecturers;
      _allStudents = allStudents;
      _selectedClass = defaultClass;

      if (_selectedClass != null) {
        _selectedLecturerName = _selectedClass!.displayLecturer != 'Chưa phân công'
            ? _selectedClass!.displayLecturer
            : (_lecturers.isNotEmpty ? '${_lecturers.first.fullName} (${_lecturers.first.lecturerCode})' : null);
        await _loadEnrolledStudentsForClass(_selectedClass!);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEnrolledStudentsForClass(CourseClassModel courseClass) async {
    final key = courseClass.id?.toString() ?? courseClass.code;
    final enrolled = await _classStudentService.getStudentsInClass(key);
    if (!mounted) return;
    setState(() {
      _enrolledStudents = enrolled;
    });
  }

  Future<void> _onSelectClass(CourseClassModel? newClass) async {
    if (newClass == null) return;
    setState(() {
      _selectedClass = newClass;
      _selectedLecturerName = newClass.displayLecturer != 'Chưa phân công'
          ? newClass.displayLecturer
          : (_lecturers.isNotEmpty ? '${_lecturers.first.fullName} (${_lecturers.first.lecturerCode})' : null);
    });
    await _loadEnrolledStudentsForClass(newClass);
  }

  // ==================== CẬP NHẬT GIẢNG VIÊN VÀO LỚP ====================
  Future<void> _saveLecturerForClass() async {
    if (_selectedClass == null || _selectedLecturerName == null) return;
    setState(() => _isSavingLecturer = true);

    try {
      LecturerModel? found;
      for (final l in _lecturers) {
        final label = '${l.fullName} (${l.lecturerCode})';
        if (label == _selectedLecturerName || l.id == _selectedLecturerName || l.lecturerCode == _selectedLecturerName) {
          found = l;
          break;
        }
      }

      final updatedClass = CourseClassModel(
        id: _selectedClass!.id,
        code: _selectedClass!.code,
        subjectId: _selectedClass!.subjectId,
        semester: _selectedClass!.semester,
        academicYear: _selectedClass!.academicYear,
        capacity: _selectedClass!.capacity,
        lecturerId: found?.id ?? _selectedLecturerName,
        lecturerCode: found?.lecturerCode,
        lecturerName: found?.fullName ?? _selectedLecturerName,
        lecturer: found,
      );

      if (_selectedClass!.id != null) {
        await _academicService.updateCourseClass(_selectedClass!.id!, updatedClass).catchError((_) => <String, dynamic>{});
      }

      // Cập nhật local list
      final idx = _classes.indexWhere((c) => c.code == _selectedClass!.code);
      if (idx != -1) {
        _classes[idx] = updatedClass;
      }
      _selectedClass = updatedClass;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gán Giảng viên "$_selectedLecturerName" cho lớp ${_selectedClass!.code}!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật giảng viên: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSavingLecturer = false);
    }
  }

  // ==================== THÊM SINH VIÊN VÀO LỚP ====================
  void _showAddStudentDialog() {
    if (_selectedClass == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final enrolledCodes = _enrolledStudents.map((s) => s.studentCode.toUpperCase()).toSet();
    final available = _allStudents.where((s) => !enrolledCodes.contains(s.studentCode.toUpperCase())).toList();

    if (available.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Tất cả sinh viên trong hệ thống đã có trong lớp này!')),
      );
      return;
    }

    String selectedStudentCode = available.first.studentCode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: Text('Thêm sinh viên vào lớp ${_selectedClass!.code}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn sinh viên từ danh mục nhà trường:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStudentCode,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sinh viên *'),
                  items: available.map((s) {
                    return DropdownMenuItem(
                      value: s.studentCode,
                      child: Text(
                        '${s.studentCode} - ${s.fullName} (${s.major.isNotEmpty ? s.major : s.faculty})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStudentCode = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              FilledButton(
                onPressed: () async {
                  final addedCode = selectedStudentCode;
                  Navigator.pop(ctx);
                  final classKey = _selectedClass!.id?.toString() ?? _selectedClass!.code;
                  await _classStudentService.addStudentToClass(classKey, addedCode);
                  await _loadEnrolledStudentsForClass(_selectedClass!);

                  final addedStudent = _allStudents.firstWhere((s) => s.studentCode == addedCode);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm sinh viên ${addedStudent.fullName} (${addedStudent.studentCode}) vào lớp ${_selectedClass!.code}!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                },
                child: const Text('Thêm vào lớp'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== XÓA SINH VIÊN KHỎI LỚP ====================
  Future<void> _removeStudent(StudentModel student) async {
    if (_selectedClass == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa sinh viên'),
        content: Text('Bạn có chắc muốn xóa sinh viên "${student.fullName} (${student.studentCode})" khỏi lớp ${_selectedClass!.code}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa khỏi lớp'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final classKey = _selectedClass!.id?.toString() ?? _selectedClass!.code;
      await _classStudentService.removeStudentFromClass(classKey, student.studentCode);
      await _loadEnrolledStudentsForClass(_selectedClass!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa ${student.fullName} khỏi lớp!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân công Giảng viên & Sinh viên vào Lớp'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Chọn lớp học phần
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.class_, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text('CHỌN LỚP HỌC PHẦN ĐỂ PHÂN CÔNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<CourseClassModel>(
                            initialValue: _selectedClass,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Lớp học phần *',
                              border: OutlineInputBorder(),
                            ),
                            items: _classes.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.code} - ${c.semester} (Năm ${c.academicYear})'),
                              );
                            }).toList(),
                            onChanged: _onSelectClass,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD 1: PHÂN CÔNG GIẢNG VIÊN DẠY LỚP NÀY
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.person_pin, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text('1. GIẢNG VIÊN PHỤ TRÁCH LỚP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.teal.shade200),
                                ),
                                child: const Text('Phân công GV', style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedLecturerName,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Chọn Giảng viên *',
                              prefixIcon: Icon(Icons.school),
                              border: OutlineInputBorder(),
                            ),
                            items: _lecturers.map((l) {
                              final text = '${l.fullName} (${l.lecturerCode})';
                              return DropdownMenuItem(
                                value: text,
                                child: Text('$text - ${l.department}', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedLecturerName = val),
                          ),
                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                              onPressed: _isSavingLecturer ? null : _saveLecturerForClass,
                              icon: _isSavingLecturer
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save),
                              label: const Text('Lưu phân công Giảng viên'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD 2: THÊM SINH VIÊN VÀO LỚP
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.groups, color: Colors.indigo),
                                      SizedBox(width: 8),
                                      Text('2. DANH SÁCH SINH VIÊN TRONG LỚP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sĩ số hiện tại: ${_enrolledStudents.length} sinh viên',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('+ Thêm Sinh viên'),
                                onPressed: _showAddStudentDialog,
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          if (_enrolledStudents.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: Column(
                                children: const [
                                  Icon(Icons.person_off, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Lớp này chưa có sinh viên nào. Bấm nút "+ Thêm Sinh viên" để đưa sinh viên vào lớp!'),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _enrolledStudents.length,
                              separatorBuilder: (context, _) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final s = _enrolledStudents[idx];
                                final hasPhoto = s.photoBase64 != null && s.photoBase64!.isNotEmpty;

                                return ListTile(
                                  tileColor: Colors.grey.shade50,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo.shade100,
                                    child: Text(
                                      s.studentCode.length >= 2 ? s.studentCode.substring(s.studentCode.length - 2) : s.studentCode,
                                      style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: hasPhoto ? Colors.green.shade50 : Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: hasPhoto ? Colors.green.shade300 : Colors.amber.shade300),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(hasPhoto ? Icons.face : Icons.no_photography, size: 12, color: hasPhoto ? Colors.green : Colors.amber.shade900),
                                            const SizedBox(width: 4),
                                            Text(
                                              hasPhoto ? 'Đã có ảnh mặt' : 'Chưa có ảnh mặt',
                                              style: TextStyle(fontSize: 10, color: hasPhoto ? Colors.green.shade900 : Colors.amber.shade900, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text('MSSV: ${s.studentCode}  •  ${s.major.isNotEmpty ? s.major : s.faculty}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Xóa khỏi lớp',
                                    onPressed: () => _removeStudent(s),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
