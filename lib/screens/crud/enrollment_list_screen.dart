import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/enrollment_model.dart';
import 'package:nguyenhuudung/services/academic_service.dart';

class EnrollmentListScreen extends StatefulWidget {
  final bool readOnly;

  const EnrollmentListScreen({super.key, this.readOnly = false});

  @override
  State<EnrollmentListScreen> createState() => _EnrollmentListScreenState();
}

class _EnrollmentListScreenState extends State<EnrollmentListScreen> {
  final _service = AcademicService();
  List<EnrollmentModel> _enrollments = [];
  List<CourseClassModel> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;

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
        _service.getEnrollments(),
        _service.getCourseClasses(),
      ]);
      if (!mounted) return;
      setState(() {
        _enrollments = results[0] as List<EnrollmentModel>;
        _classes = results[1] as List<CourseClassModel>;
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

  void _showEnrollmentDialog({EnrollmentModel? enrollment}) {
    if (widget.readOnly) return;
    final isEditing = enrollment != null;
    final studentIdCtrl = TextEditingController(text: enrollment?.studentId ?? '');
    int? selectedClassId = enrollment?.courseClassId ?? (_classes.isNotEmpty ? _classes.first.id : null);
    int status = enrollment?.status ?? 0;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Sửa đăng ký học' : 'Đăng ký học phần mới'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: studentIdCtrl,
                      decoration: const InputDecoration(labelText: 'Student ID (GUID) *', hintText: 'Mã UUID sinh viên'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập ID sinh viên' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_classes.isNotEmpty)
                      DropdownButtonFormField<int>(
                        initialValue: selectedClassId,
                        decoration: const InputDecoration(labelText: 'Lớp học phần *'),
                        items: _classes
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text('${c.code} (${c.semester})'),
                                ))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedClassId = val),
                        validator: (v) => v == null ? 'Vui lòng chọn lớp học phần' : null,
                      )
                    else
                      TextFormField(
                        initialValue: (selectedClassId ?? 1).toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Mã ID Lớp học phần *'),
                        onChanged: (v) => selectedClassId = int.tryParse(v) ?? 1,
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Trạng thái học'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('0 - Đang học (Active)')),
                        DropdownMenuItem(value: 1, child: Text('1 - Đã rút môn (Dropped)')),
                        DropdownMenuItem(value: 2, child: Text('2 - Hoàn thành (Completed)')),
                      ],
                      onChanged: (val) => setDialogState(() => status = val ?? 0),
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
                  if (selectedClassId == null) {
                    _showSnackbar('Vui lòng chọn lớp học phần!', isError: true);
                    return;
                  }
                  Navigator.pop(ctx);

                  final newEnrollment = EnrollmentModel(
                    id: enrollment?.id,
                    courseClassId: selectedClassId!,
                    studentId: studentIdCtrl.text.trim(),
                    status: status,
                    enrolledAtUtc: DateTime.now().toUtc(),
                  );

                  try {
                    if (isEditing) {
                      await _service.updateEnrollment(enrollment.id!, newEnrollment);
                      _showSnackbar('Cập nhật đăng ký thành công!');
                    } else {
                      await _service.createEnrollment(newEnrollment);
                      _showSnackbar('Đăng ký lớp học phần thành công!');
                    }
                    _loadData();
                  } catch (e) {
                    _showSnackbar('Lỗi: $e', isError: true);
                  }
                },
                child: Text(isEditing ? 'Cập nhật' : 'Đăng ký'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteEnrollment(EnrollmentModel item) async {
    if (widget.readOnly) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn hủy bản ghi đăng ký này?'),
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
        await _service.deleteEnrollment(item.id!);
        _showSnackbar('Đã hủy đăng ký thành công!');
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
        title: Text(widget.readOnly ? 'Danh sách Đăng ký (Xem thông tin)' : 'Quản lý Đăng ký (Enrollments)'),
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
              onPressed: () => _showEnrollmentDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Đăng ký lớp'),
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
                    : _enrollments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_outlined, size: 54, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('Chưa có bản ghi đăng ký nào.'),
                                if (!widget.readOnly) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () => _showEnrollmentDialog(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Đăng ký sinh viên vào lớp'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _enrollments.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _enrollments[index];
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal.shade50,
                                    child: const Icon(Icons.assignment_ind, color: Colors.teal),
                                  ),
                                  title: Text(
                                    'SV: ${item.studentName ?? item.studentId}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('Lớp: ${item.courseClassName ?? "ID ${item.courseClassId}"}  •  Trạng thái: ${item.statusText}'),
                                  trailing: widget.readOnly
                                      ? null
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                              onPressed: () => _showEnrollmentDialog(enrollment: item),
                                              tooltip: 'Sửa',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () => _deleteEnrollment(item),
                                              tooltip: 'Xóa',
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
