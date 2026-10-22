import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nguyenhuudung/core/api_client.dart';
import 'package:nguyenhuudung/core/token_storage.dart';
import 'package:nguyenhuudung/models/student_model.dart';

class StudentService {
  static const String _storageKey = 'managed_students_list';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String sampleAvatarBase64 =
      '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';

  /// Chuyển đổi bất kỳ mã sinh viên hoặc chuỗi ID nào thành định dạng UUID / uniqueidentifier hợp lệ của SQL Server
  static String toGuid(String input) {
    final clean = input.trim().toLowerCase();
    final guidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    if (guidRegex.hasMatch(clean)) {
      return clean;
    }

    final upper = input.trim().toUpperCase();
    if (upper == 'SV000299' || upper == 'SV-000299') {
      return 'e2360a44-9dcd-4239-adfd-08df2fafa03f';
    }
    if (upper == 'SV000101' || upper == 'SV-000101') {
      return 'cda04164-4266-45ab-adfe-08df2fafa03f';
    }
    if (upper == 'SV000102' || upper == 'SV-000102') {
      return 'c54113dc-f218-446a-adff-08df2fafa03f';
    }
    if (upper == 'SV000103' || upper == 'SV-000103') {
      return 'e0c1d68a-3c8c-428a-ae00-08df2fafa03f';
    }
    if (upper == 'SV000300' || upper == 'SV-000300') {
      return '00000300-0000-0000-0000-000000000300';
    }
    if (upper == 'SV000301' || upper == 'SV-000301') {
      return '00000301-0000-0000-0000-000000000301';
    }

    // Trích xuất số nếu có
    final digits = RegExp(r'\d+').allMatches(upper).map((m) => m.group(0)).join();
    if (digits.isNotEmpty) {
      final padded = digits.padLeft(12, '0');
      return '00000000-0000-0000-0000-$padded';
    }

    // Fallback băm chuỗi thành 32 ký tự hex
    final bytes = utf8.encode(input);
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().padRight(32, '0').substring(0, 32);
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // Danh sách sinh viên mẫu ban đầu với ID là uniqueidentifier (GUID) chuẩn SQL Server
  static final List<StudentModel> _initialStudents = [
    StudentModel(
      id: 'e2360a44-9dcd-4239-adfd-08df2fafa03f',
      studentCode: 'SV000299',
      fullName: 'Nguyễn Hữu Dũng',
      email: 'huudung.student@gmail.com',
      faculty: 'Công nghệ thông tin',
      major: 'Kỹ thuật phần mềm',
      phoneNumber: '0912345678',
      photoBase64: sampleAvatarBase64,
    ),
    StudentModel(
      id: 'cda04164-4266-45ab-adfe-08df2fafa03f',
      studentCode: 'SV000101',
      fullName: 'Trần Minh Quân',
      email: 'minhquan@gmail.com',
      faculty: 'Công nghệ thông tin',
      major: 'Kỹ thuật phần mềm',
      phoneNumber: '0912345678',
      photoBase64: sampleAvatarBase64,
    ),
    StudentModel(
      id: 'c54113dc-f218-446a-adff-08df2fafa03f',
      studentCode: 'SV000102',
      fullName: 'Lê Ngọc Ánh',
      email: 'ngocanh@gmail.com',
      faculty: 'Công nghệ thông tin',
      major: 'Công nghệ thông tin',
      phoneNumber: '0912345678',
      photoBase64: sampleAvatarBase64,
    ),
  ];

  Future<List<StudentModel>> getStudents() async {
    // 1. Thử lấy danh sách mới nhất từ Backend API
    try {
      final token = await TokenStorage().getToken();
      final res = await ApiClient().get('/students', token: token);
      final rawList = res['data'];
      if (rawList is List && rawList.isNotEmpty) {
        final list = rawList
            .map((item) => StudentModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        await _saveList(list);
        return list;
      }
    } catch (_) {}

    // 2. Fallback đọc từ cache an toàn
    final rawJson = await _storage.read(key: _storageKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final list = jsonDecode(rawJson) as List;
        final parsed = list
            .map((item) => StudentModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}
    }

    await _saveList(_initialStudents);
    return List<StudentModel>.from(_initialStudents);
  }

  Future<void> updateStudentPhoto(String studentCode, String base64Photo) async {
    final list = await getStudents();
    final normalized = studentCode.trim().toUpperCase();
    final cleanGuid = studentCode.trim().toLowerCase();
    final index = list.indexWhere((s) =>
        s.studentCode.trim().toUpperCase() == normalized ||
        s.id.toLowerCase() == cleanGuid ||
        toGuid(s.studentCode) == cleanGuid);
    if (index != -1) {
      list[index] = list[index].copyWith(photoBase64: base64Photo);
      await _saveList(list);
    }
  }

  Future<void> addStudent(StudentModel student) async {
    final list = await getStudents();
    final validGuid = toGuid(student.id.isNotEmpty ? student.id : student.studentCode);
    final updatedStudent = student.copyWith(id: validGuid);
    list.insert(0, updatedStudent);
    await _saveList(list);

    // Đồng bộ lên API Backend
    try {
      final token = await TokenStorage().getToken();
      final username = student.studentCode.isNotEmpty
          ? student.studentCode.toLowerCase()
          : (student.email.contains('@') ? student.email.split('@').first : 'student_${DateTime.now().millisecondsSinceEpoch}');
      await ApiClient().post(
        '/students',
        body: {
          'username': username,
          'email': student.email,
          'fullName': student.fullName,
          'phoneNumber': student.phoneNumber,
          'password': 'Student@123',
          'faculty': student.faculty,
          'major': student.major,
          'enrollmentYear': DateTime.now().year,
        },
        token: token,
      );
      if (student.photoBase64 != null && student.photoBase64!.isNotEmpty) {
        final identifier = student.studentCode.isNotEmpty ? student.studentCode : validGuid;
        await ApiClient().put(
          '/students/$identifier',
          body: {
            'fullName': student.fullName,
            'email': student.email,
            'phoneNumber': student.phoneNumber,
            'faculty': student.faculty,
            'major': student.major,
            'avatarUrl': student.photoBase64,
          },
          token: token,
        );
      }
    } catch (_) {}
  }

  Future<void> updateStudent(StudentModel student) async {
    final list = await getStudents();
    final index = list.indexWhere((s) => s.id == student.id || s.studentCode.toUpperCase() == student.studentCode.toUpperCase());
    if (index != -1) {
      list[index] = student;
      await _saveList(list);
    }

    // Đồng bộ lên API Backend
    try {
      final token = await TokenStorage().getToken();
      final identifier = student.studentCode.isNotEmpty ? student.studentCode : student.id;
      await ApiClient().put(
        '/students/$identifier',
        body: {
          'fullName': student.fullName,
          'email': student.email,
          'phoneNumber': student.phoneNumber,
          'faculty': student.faculty,
          'major': student.major,
          'avatarUrl': student.photoBase64,
        },
        token: token,
      );
    } catch (_) {}
  }

  Future<void> deleteStudent(String id) async {
    final list = await getStudents();
    final cleanGuid = id.trim().toLowerCase();
    list.removeWhere((s) => s.id.toLowerCase() == cleanGuid || s.studentCode.toUpperCase() == id.toUpperCase());
    await _saveList(list);

    // Đồng bộ lên API Backend
    try {
      final token = await TokenStorage().getToken();
      await ApiClient().delete(
        '/students/$id',
        token: token,
      );
    } catch (_) {}
  }

  Future<StudentModel?> findByCode(String code) async {
    final list = await getStudents();
    final normalized = code.trim().toUpperCase();
    final cleanGuid = code.trim().toLowerCase();
    try {
      return list.firstWhere(
        (s) =>
            s.studentCode.trim().toUpperCase() == normalized ||
            s.id.toLowerCase() == cleanGuid ||
            toGuid(s.studentCode) == cleanGuid,
      );
    } catch (_) {
      return null;
    }
  }

  Future<StudentModel?> findById(String id) async {
    return findByCode(id);
  }

  Future<void> _saveList(List<StudentModel> list) async {
    final jsonString = jsonEncode(list.map((s) => s.toJson()).toList());
    await _storage.write(key: _storageKey, value: jsonString);
  }
}
