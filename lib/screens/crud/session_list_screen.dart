import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/class_session_model.dart';
import 'package:nguyenhuudung/screens/crud/attendance_screen.dart';
import 'package:nguyenhuudung/screens/teacher/qr_display_attendance_screen.dart';
import 'package:nguyenhuudung/services/academic_service.dart';

class SessionListScreen extends StatefulWidget {
  final int courseClassId;
  final String courseClassName;
  final bool readOnly;

  const SessionListScreen({
    super.key,
    required this.courseClassId,
    this.courseClassName = 'Lớp học phần',
    this.readOnly = false,
  });

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final _service = AcademicService();
  List<ClassSessionModel> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getSessionsByCourseClass(widget.courseClassId);
      if (!mounted) return;
      setState(() {
        _sessions = list;
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

  void _showSessionDialog({ClassSessionModel? session}) {
    if (widget.readOnly) return;
    final isEditing = session != null;
    final roomCtrl = TextEditingController(text: session?.room ?? 'A101');
    final topicCtrl = TextEditingController(text: session?.topic ?? 'Buổi học lý thuyết');
    final sessionNumCtrl = TextEditingController(text: (session?.sessionNumber ?? (_sessions.length + 1)).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Sửa buổi học' : 'Thêm buổi học mới'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: sessionNumCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số thứ tự buổi *', hintText: '1'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nhập số thứ tự' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: roomCtrl,
                decoration: const InputDecoration(labelText: 'Phòng học *', hintText: 'P.302 - Nhà A'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập phòng học' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: topicCtrl,
                decoration: const InputDecoration(labelText: 'Chủ đề / Nội dung bài học', hintText: 'Chương 1: Tổng quan'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              final newSession = ClassSessionModel(
                id: session?.id,
                courseClassId: widget.courseClassId,
                sessionNumber: int.tryParse(sessionNumCtrl.text.trim()) ?? 1,
                room: roomCtrl.text.trim(),
                topic: topicCtrl.text.trim(),
                startTime: DateTime.now(),
                endTime: DateTime.now().add(const Duration(hours: 2)),
              );

              try {
                if (isEditing) {
                  await _service.updateSession(session.id!, newSession);
                  _showSnackbar('Cập nhật buổi học thành công!');
                } else {
                  await _service.createSession(widget.courseClassId, newSession);
                  _showSnackbar('Thêm buổi học thành công!');
                }
                _loadSessions();
              } catch (e) {
                _showSnackbar('Lỗi: $e', isError: true);
              }
            },
            child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(ClassSessionModel session) async {
    if (widget.readOnly) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa Buổi ${session.sessionNumber ?? ''} (${session.room})?'),
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
        await _service.deleteSession(session.id!);
        _showSnackbar('Đã xóa buổi học thành công!');
        _loadSessions();
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
        title: Text(widget.readOnly ? 'Buổi học: ${widget.courseClassName} (Xem)' : 'Buổi học: ${widget.courseClassName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showSessionDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm buổi học'),
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
                      FilledButton(onPressed: _loadSessions, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_busy, size: 54, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Lớp này chưa có buổi học nào.'),
                          if (!widget.readOnly) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _showSessionDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm buổi học đầu tiên'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _sessions.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _sessions[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.shade50,
                              child: Text(
                                '#${item.sessionNumber ?? index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                            ),
                            title: Text(
                              'Buổi ${item.sessionNumber ?? index + 1}: ${item.topic ?? "Buổi học"}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Phòng: ${item.room}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                                  icon: const Icon(Icons.qr_code_2, size: 18),
                                  label: const Text('Tạo QR & Điểm danh'),
                                  onPressed: () {
                                    final sId = item.id?.toString() ?? 'session_${index + 1}';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QrDisplayAttendanceScreen(
                                          sessionId: sId,
                                          courseClassCode: widget.courseClassName,
                                          sessionTitle: 'Buổi ${item.sessionNumber ?? index + 1} (${item.room})',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (!widget.readOnly) ...[
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'view_attendance') {
                                        if (item.id != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AttendanceScreen(
                                                sessionId: item.id!,
                                                sessionTitle: 'Buổi ${item.sessionNumber ?? index + 1} (${item.room})',
                                                readOnly: true,
                                              ),
                                            ),
                                          );
                                        }
                                      } else if (val == 'edit') {
                                        _showSessionDialog(session: item);
                                      } else if (val == 'delete') {
                                        _deleteSession(item);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'view_attendance',
                                        child: Row(
                                          children: [
                                            Icon(Icons.checklist, color: Colors.blue, size: 18),
                                            SizedBox(width: 8),
                                            Text('Xem danh sách điểm danh'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(value: 'edit', child: Text('Sửa buổi học')),
                                      PopupMenuItem(value: 'delete', child: Text('Xóa buổi học', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
