import 'package:flutter/material.dart';
import 'package:nguyenhuudung/models/subject_model.dart';
import 'package:nguyenhuudung/services/academic_service.dart';

class SubjectListScreen extends StatefulWidget {
  final bool readOnly;

  const SubjectListScreen({super.key, this.readOnly = false});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final _service = AcademicService();
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getSubjects();
      if (!mounted) return;
      setState(() {
        _subjects = list;
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

  List<SubjectModel> get _filteredSubjects {
    if (_searchQuery.trim().isEmpty) return _subjects;
    final q = _searchQuery.toLowerCase();
    return _subjects.where((s) => s.code.toLowerCase().contains(q) || s.name.toLowerCase().contains(q)).toList();
  }

  void _showSubjectDetailDialog(SubjectModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.code} - ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Mã môn học:', item.code),
            _buildDetailRow('Tên môn học:', item.name),
            _buildDetailRow('Số tín chỉ:', '${item.credits} tín chỉ'),
            _buildDetailRow('Trạng thái:', item.isActive ? 'Đang mở giảng dạy' : 'Đã đóng'),
            _buildDetailRow('Mô tả:', item.description?.isNotEmpty == true ? item.description! : 'Không có mô tả'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _showSubjectDialog({SubjectModel? subject}) {
    if (widget.readOnly) return;
    final isEditing = subject != null;
    final codeCtrl = TextEditingController(text: subject?.code ?? '');
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    final creditsCtrl = TextEditingController(text: (subject?.credits ?? 3).toString());
    final descCtrl = TextEditingController(text: subject?.description ?? '');
    bool isActive = subject?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Sửa môn học' : 'Thêm môn học mới'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Mã môn học *', hintText: 'IT101'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mã môn' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên môn học *', hintText: 'Lập trình di động'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên môn' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: creditsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số tín chỉ *', hintText: '3'),
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Số tín chỉ không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Mô tả', hintText: 'Mô tả môn học...'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Kích hoạt / Đang giảng dạy'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx);

                  final newSubject = SubjectModel(
                    id: subject?.id,
                    code: codeCtrl.text.trim(),
                    name: nameCtrl.text.trim(),
                    credits: int.parse(creditsCtrl.text.trim()),
                    description: descCtrl.text.trim(),
                    isActive: isActive,
                  );

                  try {
                    if (isEditing) {
                      await _service.updateSubject(subject.id!, newSubject);
                      _showSnackbar('Cập nhật môn học thành công!');
                    } else {
                      await _service.createSubject(newSubject);
                      _showSnackbar('Thêm môn học thành công!');
                    }
                    _loadSubjects();
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

  Future<void> _deleteSubject(SubjectModel subject) async {
    if (widget.readOnly) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa môn học "${subject.name}" (${subject.code})?'),
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
        await _service.deleteSubject(subject.id!);
        _showSnackbar('Đã xóa môn học thành công!');
        _loadSubjects();
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
        title: Text(widget.readOnly ? 'Danh sách Môn học (Xem thông tin)' : 'Quản lý Môn học (Subjects)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubjects,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showSubjectDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm môn học'),
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
                hintText: 'Tìm kiếm theo mã môn hoặc tên môn...',
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
                            FilledButton(onPressed: _loadSubjects, child: const Text('Thử lại')),
                          ],
                        ),
                      )
                    : _filteredSubjects.isEmpty
                        ? const Center(
                            child: Text('Chưa có môn học nào hoặc không tìm thấy kết quả.'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _filteredSubjects.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _filteredSubjects[index];
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  onTap: () => _showSubjectDetailDialog(item),
                                  leading: CircleAvatar(
                                    backgroundColor: item.isActive ? Colors.indigo.shade100 : Colors.grey.shade300,
                                    child: Icon(
                                      Icons.menu_book,
                                      color: item.isActive ? Colors.indigo : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    '${item.code} - ${item.name}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Số tín chỉ: ${item.credits}  •  ${item.isActive ? "Đang mở" : "Đã đóng"}'),
                                      if (item.description != null && item.description!.isNotEmpty)
                                        Text(
                                          item.description!,
                                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                  trailing: widget.readOnly
                                      ? const Icon(Icons.chevron_right, color: Colors.grey)
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                              onPressed: () => _showSubjectDialog(subject: item),
                                              tooltip: 'Sửa',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () => _deleteSubject(item),
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
