import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/attendance_model.dart';
import 'package:nguyenhuudung/services/academic_service.dart';
import 'package:nguyenhuudung/services/class_student_service.dart';
import 'package:nguyenhuudung/services/student_service.dart';

class AttendanceScreen extends StatefulWidget {
  final int sessionId;
  final String sessionTitle;
  final bool readOnly;

  const AttendanceScreen({
    super.key,
    required this.sessionId,
    this.sessionTitle = 'Buổi học',
    this.readOnly = false,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _service = AcademicService();
  List<AttendanceModel> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
    ClassStudentService.attendanceChangeNotifier.addListener(_onAttendanceChanged);
  }

  void _onAttendanceChanged() {
    if (mounted) _loadAttendance();
  }

  @override
  void dispose() {
    ClassStudentService.attendanceChangeNotifier.removeListener(_onAttendanceChanged);
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getAttendanceBySession(widget.sessionId);
      final local = await ClassStudentService().getSessionAttendance(widget.sessionId.toString(), '');
      
      // Đồng bộ trạng thái có mặt từ ClassStudentService vào danh sách API
      for (final localItem in local) {
        if (localItem.isPresent) {
          final targetGuid = StudentService.toGuid(localItem.studentCode);
          final index = list.indexWhere((a) =>
              a.studentId.toUpperCase() == localItem.studentCode.toUpperCase() ||
              a.studentId.toLowerCase() == targetGuid.toLowerCase() ||
              (localItem.studentId != null && a.studentId.toLowerCase() == localItem.studentId!.toLowerCase()));
          if (index != -1) {
            final old = list[index];
            list[index] = AttendanceModel(
              id: old.id,
              classSessionId: widget.sessionId,
              studentId: old.studentId,
              studentName: old.studentName ?? localItem.studentName,
              status: 0, // Có mặt
              isFaceVerified: localItem.isFaceVerified,
              capturedFaceUrl: localItem.capturedFaceBase64 ?? old.capturedFaceUrl,
              latitude: localItem.latitude ?? old.latitude,
              longitude: localItem.longitude ?? old.longitude,
              checkedInAtUtc: localItem.markedAt ?? old.checkedInAtUtc,
              deviceInfo: localItem.deviceInfo ?? old.deviceInfo,
              note: localItem.note ?? old.note,
            );
          } else {
            list.add(AttendanceModel(
              classSessionId: widget.sessionId,
              studentId: localItem.studentId ?? targetGuid,
              studentName: localItem.studentName,
              status: 0,
              isFaceVerified: localItem.isFaceVerified,
              capturedFaceUrl: localItem.capturedFaceBase64,
              latitude: localItem.latitude,
              longitude: localItem.longitude,
              checkedInAtUtc: localItem.markedAt,
              deviceInfo: localItem.deviceInfo,
              note: localItem.note,
            ));
          }
        }
      }

      if (list.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _records = list;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback đọc từ ClassStudentService nếu API rỗng hoặc chưa kết nối
    try {
      final local = await ClassStudentService().getSessionAttendance(widget.sessionId.toString(), '');
      if (local.isNotEmpty) {
        final mapped = local.map((item) => AttendanceModel(
          classSessionId: widget.sessionId,
          studentId: item.studentId ?? StudentService.toGuid(item.studentCode),
          studentName: item.studentName,
          status: item.isPresent ? 0 : item.status,
          isFaceVerified: item.isFaceVerified,
          capturedFaceUrl: item.capturedFaceBase64,
          latitude: item.latitude,
          longitude: item.longitude,
          checkedInAtUtc: item.markedAt,
          deviceInfo: item.deviceInfo,
          note: item.note,
        )).toList();

        if (!mounted) return;
        setState(() {
          _records = mapped;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _records = [];
      _isLoading = false;
    });
  }

  void _showAttendanceDialog({AttendanceModel? record}) {
    if (widget.readOnly) return;
    final isEditing = record != null;
    final studentIdCtrl = TextEditingController(text: record?.studentId ?? '');
    final noteCtrl = TextEditingController(text: record?.note ?? '');
    int status = record?.status ?? 0;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Cập nhật điểm danh' : 'Điểm danh sinh viên'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: studentIdCtrl,
                      enabled: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Student ID (GUID) *',
                        hintText: 'Nhập mã UUID sinh viên',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập ID sinh viên' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Trạng thái điểm danh'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('0 - Có mặt (Present)')),
                        DropdownMenuItem(value: 1, child: Text('1 - Vắng mặt (Absent)')),
                        DropdownMenuItem(value: 2, child: Text('2 - Đi muộn (Late)')),
                        DropdownMenuItem(value: 3, child: Text('3 - Có phép (Excused)')),
                      ],
                      onChanged: (val) => setDialogState(() => status = val ?? 0),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
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
                  Navigator.pop(ctx);

                  final inputId = studentIdCtrl.text.trim();
                  final validGuid = StudentService.toGuid(inputId);

                  final newRecord = AttendanceModel(
                    id: record?.id,
                    classSessionId: widget.sessionId,
                    studentId: validGuid,
                    status: status,
                    isFaceVerified: status == 0,
                    note: noteCtrl.text.trim(),
                    checkedInAtUtc: DateTime.now().toUtc(),
                    deviceInfo: 'Mobile Flutter App',
                  );

                  try {
                    if (isEditing) {
                      await _service.updateAttendance(record.id!, newRecord);
                      _showSnackbar('Cập nhật điểm danh thành công!');
                    } else {
                      await _service.markAttendance(newRecord);
                      _showSnackbar('Điểm danh thành công!');
                    }
                    _loadAttendance();
                  } catch (e) {
                    _showSnackbar('Lỗi: $e', isError: true);
                  }
                },
                child: Text(isEditing ? 'Lưu' : 'Điểm danh'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteRecord(AttendanceModel record) async {
    if (widget.readOnly) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bản ghi điểm danh này?'),
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
        await _service.deleteAttendance(record.id!);
        _showSnackbar('Đã xóa bản ghi điểm danh!');
        _loadAttendance();
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

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? 'Điểm danh: ${widget.sessionTitle} (Xem)' : 'Điểm danh: ${widget.sessionTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendance,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAttendanceDialog(),
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Điểm danh SV'),
            ),
      body: _isLoading
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
                      FilledButton(onPressed: _loadAttendance, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.playlist_remove, size: 54, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Chưa có sinh viên nào được điểm danh trong buổi học này.'),
                          if (!widget.readOnly) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _showAttendanceDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Điểm danh ngay'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _records.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _records[index];
                        final color = _getStatusColor(item.status);
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(Icons.person, color: color),
                            ),
                            title: Text(
                              item.studentName ?? item.studentId,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.statusText,
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    if (item.markedAtUtc != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        'Lúc: ${item.markedAtUtc!.toLocal().toString().substring(11, 16)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ],
                                ),
                                if (item.note != null && item.note!.isNotEmpty)
                                  Text('Ghi chú: ${item.note!}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            trailing: widget.readOnly
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                        onPressed: () => _showAttendanceDialog(record: item),
                                        tooltip: 'Cập nhật',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteRecord(item),
                                        tooltip: 'Xóa',
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
    );
  }
}
