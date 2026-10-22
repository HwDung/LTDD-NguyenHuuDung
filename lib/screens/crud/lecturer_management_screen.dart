import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/lecturer_model.dart';
import 'package:nguyenhuudung/services/lecturer_service.dart';

class LecturerManagementScreen extends StatefulWidget {
  const LecturerManagementScreen({super.key});

  @override
  State<LecturerManagementScreen> createState() => _LecturerManagementScreenState();
}

class _LecturerManagementScreenState extends State<LecturerManagementScreen> {
  final _service = LecturerService();
  List<LecturerModel> _lecturers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLecturers();
  }

  Future<void> _loadLecturers() async {
    setState(() => _isLoading = true);
    final list = await _service.getLecturers();
    if (!mounted) return;
    setState(() {
      _lecturers = list;
      _isLoading = false;
    });
  }

  List<LecturerModel> get _filteredLecturers {
    if (_searchQuery.trim().isEmpty) return _lecturers;
    final q = _searchQuery.toLowerCase();
    return _lecturers.where((l) => l.fullName.toLowerCase().contains(q) || l.lecturerCode.toLowerCase().contains(q)).toList();
  }

  void _showLecturerDialog({LecturerModel? lecturer}) {
    final isEditing = lecturer != null;
    final nameCtrl = TextEditingController(text: lecturer?.fullName ?? '');
    final codeCtrl = TextEditingController(text: lecturer?.lecturerCode ?? 'GV00${_lecturers.length + 1}');
    final emailCtrl = TextEditingController(text: lecturer?.email ?? '');
    final deptCtrl = TextEditingController(text: lecturer?.department ?? 'Bộ môn Kỹ thuật phần mềm');
    final phoneCtrl = TextEditingController(text: lecturer?.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Sửa thông tin Giảng viên' : 'Thêm Giảng viên mới'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên giảng viên *', hintText: 'ThS. Trần Văn Hùng'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Mã số giảng viên (Mã GV) *', hintText: 'GV001'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập mã giảng viên' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email liên hệ *', hintText: 'hungtv@university.edu.vn'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập email giảng viên' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(labelText: 'Bộ môn / Khoa *', hintText: 'Khoa Công nghệ thông tin'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nhập bộ môn / khoa' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại', hintText: '0988776655'),
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

              final newLecturer = LecturerModel(
                id: lecturer?.id ?? 'gv-${DateTime.now().millisecondsSinceEpoch}',
                lecturerCode: codeCtrl.text.trim().toUpperCase(),
                fullName: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                department: deptCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
              );

              if (isEditing) {
                await _service.updateLecturer(newLecturer);
                _showSnackbar('Cập nhật thông tin giảng viên thành công!');
              } else {
                await _service.createLecturer(newLecturer);
                _showSnackbar('Thêm giảng viên mới thành công!');
              }
              _loadLecturers();
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm giảng viên'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLecturer(LecturerModel lecturer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa giảng viên'),
        content: Text('Bạn có chắc muốn xóa giảng viên "${lecturer.fullName}" (${lecturer.lecturerCode})?'),
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
      await _service.deleteLecturer(lecturer.id);
      _showSnackbar('Đã xóa giảng viên thành công!');
      _loadLecturers();
    }
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Giảng viên (Admin)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLecturers,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => _showLecturerDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm giảng viên'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.indigo.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Admin có toàn quyền Thêm, Sửa, Xóa thông tin Giảng viên trong trường.',
                    style: TextStyle(fontSize: 12, color: Colors.indigo.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo họ tên hoặc mã GV (GV001)...',
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
                : _filteredLecturers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_off_outlined, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('Chưa có giảng viên nào.'),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _showLecturerDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm giảng viên'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _filteredLecturers.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final l = _filteredLecturers[index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.teal.shade100,
                                child: const Icon(Icons.person, color: Colors.teal),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(l.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l.lecturerCode,
                                      style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(l.department),
                                  Text('Email: ${l.email}'),
                                  if (l.phoneNumber != null && l.phoneNumber!.isNotEmpty)
                                    Text('SĐT: ${l.phoneNumber!}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _showLecturerDialog(lecturer: l),
                                    tooltip: 'Sửa',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteLecturer(l),
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
