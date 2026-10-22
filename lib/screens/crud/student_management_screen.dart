import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nguyenhuudung/models/faculty_model.dart';
import 'package:nguyenhuudung/models/student_model.dart';
import 'package:nguyenhuudung/services/academic_service.dart';
import 'package:nguyenhuudung/services/student_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _service = StudentService();
  final _academicService = AcademicService();
  final _picker = ImagePicker();

  List<StudentModel> _students = [];
  List<FacultyModel> _faculties = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getStudents(),
      _academicService.getFaculties(),
    ]);

    if (!mounted) return;
    setState(() {
      _students = results[0] as List<StudentModel>;
      _faculties = results[1] as List<FacultyModel>;
      _isLoading = false;
    });
  }

  List<StudentModel> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) => s.fullName.toLowerCase().contains(q) || s.studentCode.toLowerCase().contains(q)).toList();
  }

  Future<void> _showStudentDialog({StudentModel? student}) async {
    final isEditing = student != null;
    final nameCtrl = TextEditingController(text: student?.fullName ?? '');
    final codeCtrl = TextEditingController(text: student?.studentCode ?? 'SV000${299 + _students.length}');
    final emailCtrl = TextEditingController(text: student?.email ?? '');
    final phoneCtrl = TextEditingController(text: student?.phoneNumber ?? '');

    // Chọn Khoa ban đầu từ dữ liệu API
    FacultyModel selectedFaculty = _faculties.firstWhere(
      (f) => f.name == (student?.faculty ?? 'Công nghệ thông tin'),
      orElse: () => _faculties.isNotEmpty
          ? _faculties.first
          : FacultyModel(id: 1, code: 'CNTT', name: 'Công nghệ thông tin', majors: [
              MajorModel(id: 1, code: 'KTPM', name: 'Kỹ thuật phần mềm', facultyId: 1),
            ]),
    );

    // Chọn Ngành ban đầu thuộc Khoa đã chọn
    MajorModel selectedMajor = selectedFaculty.majors.firstWhere(
      (m) => m.name == (student?.major ?? 'Kỹ thuật phần mềm'),
      orElse: () => selectedFaculty.majors.isNotEmpty
          ? selectedFaculty.majors.first
          : MajorModel(id: 1, code: 'KTPM', name: 'Kỹ thuật phần mềm', facultyId: selectedFaculty.id),
    );

    String? currentBase64 = student?.photoBase64;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickImage(ImageSource source) async {
            try {
              final pickedFile = await _picker.pickImage(
                source: source,
                maxWidth: 600,
                maxHeight: 600,
                imageQuality: 85,
              );
              if (pickedFile != null) {
                final bytes = await pickedFile.readAsBytes();
                final base64String = base64Encode(bytes);
                setDialogState(() {
                  currentBase64 = base64String;
                });
              }
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
              );
            }
          }

          return AlertDialog(
            title: Text(isEditing ? 'Sửa thông tin Sinh viên' : 'Thêm Sinh viên mới'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Khu vực chọn ảnh khuôn mặt phục vụ điểm danh
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: Colors.indigo.shade100,
                                backgroundImage: currentBase64 != null ? MemoryImage(base64Decode(currentBase64!)) : null,
                                child: currentBase64 == null
                                    ? const Icon(Icons.face_retouching_natural, size: 48, color: Colors.indigo)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.indigo,
                                  child: PopupMenuButton<ImageSource>(
                                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                    onSelected: pickImage,
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: ImageSource.camera,
                                        child: Row(
                                          children: [
                                            Icon(Icons.camera_alt_outlined),
                                            SizedBox(width: 8),
                                            Text('Chụp ảnh khuôn mặt'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: ImageSource.gallery,
                                        child: Row(
                                          children: [
                                            Icon(Icons.photo_library_outlined),
                                            SizedBox(width: 8),
                                            Text('Chọn ảnh từ thư viện'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentBase64 != null ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: currentBase64 != null ? Colors.green.shade300 : Colors.amber.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentBase64 != null ? Icons.check_circle : Icons.warning_amber_rounded,
                                  size: 14,
                                  color: currentBase64 != null ? Colors.green.shade700 : Colors.amber.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentBase64 != null ? 'Đã có ảnh khuôn mặt đối soát' : 'Bấm vào máy ảnh để thêm ảnh khuôn mặt',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: currentBase64 != null ? Colors.green.shade800 : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Họ và tên
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Họ và tên sinh viên *', hintText: 'Nguyễn Văn A'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 12),

                    // Mã sinh viên (format SV000299)
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Mã số sinh viên (MSSV) *', hintText: 'SV000299'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mã sinh viên' : null,
                    ),
                    const SizedBox(height: 12),

                    // Email
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email sinh viên *', hintText: 'student@edu.vn'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập email' : null,
                    ),
                    const SizedBox(height: 12),

                    // Số điện thoại
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Số điện thoại', hintText: '09xxxxxxxx'),
                    ),
                    const SizedBox(height: 12),

                    // DROPDOWN KHOA (DỮ LIỆU TỪ API)
                    DropdownButtonFormField<FacultyModel>(
                      initialValue: selectedFaculty,
                      decoration: const InputDecoration(
                        labelText: 'Khoa (Dữ liệu từ API) *',
                        prefixIcon: Icon(Icons.domain),
                      ),
                      isExpanded: true,
                      items: _faculties.map((f) {
                        return DropdownMenuItem<FacultyModel>(
                          value: f,
                          child: Text('${f.code} - ${f.name}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newFaculty) {
                        if (newFaculty != null) {
                          setDialogState(() {
                            selectedFaculty = newFaculty;
                            selectedMajor = newFaculty.majors.isNotEmpty
                                ? newFaculty.majors.first
                                : MajorModel(id: 0, code: '', name: 'Khác', facultyId: newFaculty.id);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // DROPDOWN NGÀNH (LỌC TƯƠNG ỨNG THEO KHOA ĐÃ CHỌN)
                    DropdownButtonFormField<MajorModel>(
                      key: ValueKey('major_${selectedFaculty.id}'),
                      initialValue: selectedMajor,
                      decoration: const InputDecoration(
                        labelText: 'Ngành học liên quan (Dữ liệu từ API) *',
                        prefixIcon: Icon(Icons.school),
                      ),
                      isExpanded: true,
                      items: selectedFaculty.majors.map((m) {
                        return DropdownMenuItem<MajorModel>(
                          value: m,
                          child: Text('${m.code} - ${m.name}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newMajor) {
                        if (newMajor != null) {
                          setDialogState(() {
                            selectedMajor = newMajor;
                          });
                        }
                      },
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

                  final newStudent = StudentModel(
                    id: student?.id ?? 'sv-${DateTime.now().millisecondsSinceEpoch}',
                    studentCode: codeCtrl.text.trim().toUpperCase(),
                    fullName: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.trim(),
                    faculty: selectedFaculty.name,
                    major: selectedMajor.name,
                    photoBase64: currentBase64,
                  );

                  if (isEditing) {
                    await _service.updateStudent(newStudent);
                    _showSnackbar('Cập nhật thông tin sinh viên thành công!');
                  } else {
                    await _service.addStudent(newStudent);
                    _showSnackbar('Thêm sinh viên mới thành công!');
                  }
                  _loadData();
                },
                child: Text(isEditing ? 'Lưu' : 'Thêm sinh viên'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa sinh viên'),
        content: Text('Bạn có chắc chắn muốn xóa sinh viên "${student.fullName}" (${student.studentCode}) khỏi hệ thống?'),
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
      await _service.deleteStudent(student.id);
      _showSnackbar('Đã xóa sinh viên thành công!');
      _loadData();
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
        title: const Text('Quản lý Sinh viên (Admin)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => _showStudentDialog(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm sinh viên'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.indigo.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Admin có toàn quyền Thêm, Sửa, Xóa và cập nhật Ảnh khuôn mặt dùng cho điểm danh. Khoa & Ngành lấy trực tiếp từ API.',
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
                hintText: 'Tìm theo họ tên hoặc mã SV (SV000299)...',
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
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 54, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('Chưa có sinh viên nào hoặc không tìm thấy kết quả.'),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _showStudentDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm sinh viên đầu tiên'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _filteredStudents.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          final hasPhoto = student.photoBase64 != null && student.photoBase64!.isNotEmpty;
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.indigo.shade100,
                                    backgroundImage: hasPhoto ? MemoryImage(base64Decode(student.photoBase64!)) : null,
                                    child: !hasPhoto
                                        ? Text(
                                            student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                          )
                                        : null,
                                  ),
                                  if (hasPhoto)
                                    const Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      student.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      student.studentCode,
                                      style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${student.major} • ${student.faculty}'),
                                  Text('Email: ${student.email}'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        hasPhoto ? Icons.camera_enhance : Icons.no_photography,
                                        size: 14,
                                        color: hasPhoto ? Colors.green : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasPhoto ? 'Đã có ảnh khuôn mặt AI' : 'Chưa cập nhật ảnh khuôn mặt',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: hasPhoto ? Colors.green.shade800 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _showStudentDialog(student: student),
                                    tooltip: 'Sửa thông tin & Ảnh',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteStudent(student),
                                    tooltip: 'Xóa sinh viên',
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
