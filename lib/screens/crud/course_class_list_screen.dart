import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/lecturer_model.dart';
import 'package:nguyenhuudung/models/subject_model.dart';
import 'package:nguyenhuudung/screens/crud/class_enrollment_management_screen.dart';
import 'package:nguyenhuudung/screens/crud/session_list_screen.dart';
import 'package:nguyenhuudung/services/academic_service.dart';
import 'package:nguyenhuudung/services/class_student_service.dart';
import 'package:nguyenhuudung/services/lecturer_service.dart';

class CourseClassListScreen extends StatefulWidget {
  final bool readOnly;

  const CourseClassListScreen({super.key, this.readOnly = false});

  @override
  State<CourseClassListScreen> createState() => _CourseClassListScreenState();
}

class _CourseClassListScreenState extends State<CourseClassListScreen> {
  final _service = AcademicService();
  final _lecturerService = LecturerService();
  final _classStudentService = ClassStudentService();

  List<CourseClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<LecturerModel> _lecturers = [];
  Map<String, int> _studentCounts = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getCourseClasses(),
        _service.getSubjects(),
        _lecturerService.getLecturers(),
      ]);
      final classes = results[0] as List<CourseClassModel>;
      final subjects = results[1] as List<SubjectModel>;
      final lecturers = results[2] as List<LecturerModel>;

      // Load số lượng sinh viên mỗi lớp
      final counts = <String, int>{};
      for (final c in classes) {
        final key = (c.id?.toString() ?? c.code);
        final studs = await _classStudentService.getStudentCodesInClass(key);
        counts[c.code] = studs.length;
      }

      if (!mounted) return;
      setState(() {
        _classes = classes;
        _subjects = subjects;
        _lecturers = lecturers;
        _studentCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CourseClassModel> get _filteredClasses {
    if (_searchQuery.trim().isEmpty) return _classes;
    final q = _searchQuery.toLowerCase();
    return _classes.where((c) => c.code.toLowerCase().contains(q) || c.semester.toLowerCase().contains(q)).toList();
  }

  void _showClassDialog({CourseClassModel? courseClass}) {
    if (widget.readOnly) return;
    final isEditing = courseClass != null;
    final codeCtrl = TextEditingController(text: courseClass?.code ?? '');
    final semesterCtrl = TextEditingController(text: courseClass?.semester ?? 'HK1');
    final yearCtrl = TextEditingController(text: (courseClass?.academicYear ?? 2026).toString());
    final capacityCtrl = TextEditingController(text: (courseClass?.capacity ?? 50).toString());
    int? selectedSubjectId = courseClass?.subjectId ?? (_subjects.isNotEmpty ? _subjects.first.id : null);
    String? selectedLecturer = courseClass?.lecturerId ?? (_lecturers.isNotEmpty ? '${_lecturers.first.fullName} (${_lecturers.first.lecturerCode})' : null);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Sửa lớp học phần' : 'Thêm lớp học phần'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Mã lớp *', hintText: 'COMP101_01'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mã lớp' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_subjects.isNotEmpty)
                      DropdownButtonFormField<int>(
                        initialValue: selectedSubjectId,
                        decoration: const InputDecoration(labelText: 'Môn học *'),
                        items: _subjects
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text('${s.code} - ${s.name}', overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                        validator: (v) => v == null ? 'Vui lòng chọn môn học' : null,
                      )
                    else
                      TextFormField(
                        initialValue: (selectedSubjectId ?? 1).toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Mã ID môn học *'),
                        onChanged: (v) => selectedSubjectId = int.tryParse(v) ?? 1,
                      ),
                    const SizedBox(height: 12),
                    if (_lecturers.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedLecturer != null && _lecturers.any((l) => '${l.fullName} (${l.lecturerCode})' == selectedLecturer)
                            ? selectedLecturer
                            : '${_lecturers.first.fullName} (${_lecturers.first.lecturerCode})',
                        decoration: const InputDecoration(labelText: 'Giảng viên phụ trách *'),
                        items: _lecturers
                            .map((l) => DropdownMenuItem(
                                  value: '${l.fullName} (${l.lecturerCode})',
                                  child: Text('${l.fullName} (${l.lecturerCode})', overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedLecturer = val),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: semesterCtrl,
                      decoration: const InputDecoration(labelText: 'Học kỳ *', hintText: 'Học kỳ 1'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập học kỳ' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: yearCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Năm học *', hintText: '2026'),
                            validator: (v) => int.tryParse(v ?? '') == null ? 'Năm không hợp lệ' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Sĩ số tối đa *', hintText: '50'),
                            validator: (v) => int.tryParse(v ?? '') == null ? 'Sĩ số không hợp lệ' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (selectedSubjectId == null) {
                    _showSnackbar('Vui lòng chọn môn học!', isError: true);
                    return;
                  }
                  Navigator.pop(ctx);

                  LecturerModel? foundLecturer;
                  for (final l in _lecturers) {
                    final label = '${l.fullName} (${l.lecturerCode})';
                    if (label == selectedLecturer || l.id == selectedLecturer || l.lecturerCode == selectedLecturer) {
                      foundLecturer = l;
                      break;
                    }
                  }

                  final newClass = CourseClassModel(
                    id: courseClass?.id,
                    code: codeCtrl.text.trim(),
                    subjectId: selectedSubjectId!,
                    semester: semesterCtrl.text.trim(),
                    academicYear: int.parse(yearCtrl.text.trim()),
                    capacity: int.parse(capacityCtrl.text.trim()),
                    lecturerId: foundLecturer?.id ?? selectedLecturer,
                    lecturerCode: foundLecturer?.lecturerCode,
                    lecturerName: foundLecturer?.fullName ?? selectedLecturer,
                  );

                  try {
                    if (isEditing) {
                      await _service.updateCourseClass(courseClass.id!, newClass);
                      _showSnackbar('Cập nhật lớp học phần thành công!');
                    } else {
                      await _service.createCourseClass(newClass);
                      _showSnackbar('Thêm lớp học phần thành công!');
                    }
                    _loadData();
                  } catch (e) {
                    _showSnackbar('Lỗi: $e', isError: true);
                  }
                },
                child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteClass(CourseClassModel item) async {
    if (widget.readOnly) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa lớp học phần "${item.code}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteCourseClass(item.id!);
        _showSnackbar('Đã xóa lớp học phần thành công!');
        _loadData();
      } catch (e) {
        _showSnackbar('Lỗi khi xóa: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? 'Danh sách Lớp học phần (Xem thông tin)' : 'Quản lý Lớp học phần (Course Classes)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showClassDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm lớp học phần'),
            ),
      body: Column(
        children: [
          if (widget.readOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chế độ xem thông tin: Không hỗ trợ thêm, xóa, sửa.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo mã lớp, học kỳ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _loadData, child: const Text('Thử lại')),
                          ],
                        ),
                      )
                    : _filteredClasses.isEmpty
                        ? const Center(child: Text('Chưa có lớp học phần nào.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _filteredClasses.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _filteredClasses[index];
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
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
                                              color: Colors.indigo.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${item.semester} - Năm ${item.academicYear}',
                                              style: TextStyle(color: Colors.indigo.shade800, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Môn học: ${item.subject?.name ?? "ID: ${item.subjectId}"}  •  Sĩ số tối đa: ${item.capacity}',
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.indigo),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Giảng viên: ${item.displayLecturer}',
                                              style: TextStyle(fontSize: 13, color: Colors.indigo.shade900, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              FilledButton.tonalIcon(
                                                icon: const Icon(Icons.group_add, size: 18),
                                                label: Text('Gán GV & SV (${_studentCounts[item.code] ?? 0})'),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ClassEnrollmentManagementScreen(
                                                        initialClassId: item.id,
                                                        initialClassCode: item.code,
                                                      ),
                                                    ),
                                                  ).then((_) => _loadData());
                                                },
                                              ),
                                              OutlinedButton.icon(
                                                icon: const Icon(Icons.calendar_month, size: 18),
                                                label: Text(widget.readOnly ? 'Xem Buổi học' : 'Buổi học'),
                                                onPressed: () {
                                                  if (item.id != null) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => SessionListScreen(
                                                          courseClassId: item.id!,
                                                          courseClassName: item.code,
                                                          readOnly: widget.readOnly,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          if (!widget.readOnly)
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                                  onPressed: () => _showClassDialog(courseClass: item),
                                                  tooltip: 'Sửa',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                  onPressed: () => _deleteClass(item),
                                                  tooltip: 'Xóa',
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
