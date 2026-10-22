import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nguyenhuudung/core/api_client.dart';
import 'package:nguyenhuudung/core/token_storage.dart';
import 'package:nguyenhuudung/models/student_model.dart';

class StudentService {
  static const String _storageKey = 'managed_students_list';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String sampleAvatarBase64 = StudentModel.defaultAvatarBase64;

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

      // Đồng bộ ảnh khuôn mặt mẫu lên Backend API để lưu vĩnh viễn vào SQL Server
      final studentId = list[index].id;
      final studentCd = list[index].studentCode;
      try {
        final token = await TokenStorage().getToken();
        await ApiClient().put(
          '/students/$studentId/avatar',
          body: {'avatarUrl': base64Photo},
          token: token,
        );
      } catch (e) {
        try {
          final token = await TokenStorage().getToken();
          await ApiClient().put(
            '/students/$studentCd',
            body: {
              'fullName': list[index].fullName,
              'email': list[index].email,
              'studentCode': list[index].studentCode,
              'faculty': list[index].faculty,
              'major': list[index].major,
              'avatarUrl': base64Photo,
            },
            token: token,
          );
        } catch (_) {}
      }
    }
  }

  Future<void> addStudent(StudentModel student) async {
    final validGuid = toGuid(student.id.isNotEmpty ? student.id : student.studentCode);
    StudentModel finalStudent = student.copyWith(id: validGuid);

    // Đồng bộ lên API Backend trước
    try {
      final token = await TokenStorage().getToken();
      final username = student.studentCode.isNotEmpty
          ? student.studentCode.toLowerCase()
          : (student.email.contains('@') ? student.email.split('@').first : 'student_${DateTime.now().millisecondsSinceEpoch}');
      final res = await ApiClient().post(
        '/students',
        body: {
          'username': username,
          'email': student.email.trim(),
          'fullName': student.fullName.trim(),
          'studentCode': student.studentCode.trim().toUpperCase(),
          'phoneNumber': student.phoneNumber?.trim(),
          'password': 'Student@123',
          'faculty': student.faculty,
          'major': student.major,
          'enrollmentYear': DateTime.now().year,
          'avatarUrl': student.photoBase64,
        },
        token: token,
      );
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
      final serverId = (data['userId'] ?? data['id'])?.toString();
      final serverCode = data['studentCode']?.toString();
      finalStudent = student.copyWith(
        id: serverId ?? validGuid,
        studentCode: serverCode ?? student.studentCode,
      );
    } catch (e) {
      // Nếu API lỗi mạng hoặc server trả về lỗi nghiệp vụ, vẫn cập nhật offline nhưng rethrow nếu cần thông báo
      debugPrint('Lỗi thêm sinh viên qua API: $e');
      rethrow;
    }

    final list = await getStudents();
    list.removeWhere((s) => s.id == finalStudent.id || s.studentCode.toUpperCase() == finalStudent.studentCode.toUpperCase());
    list.insert(0, finalStudent);
    await _saveList(list);
  }

  Future<void> updateStudent(StudentModel student) async {
    final token = await TokenStorage().getToken();
    final identifier = student.studentCode.isNotEmpty ? student.studentCode : student.id;

    // Đồng bộ lên API Backend
    try {
      await ApiClient().put(
        '/students/$identifier',
        body: {
          'fullName': student.fullName.trim(),
          'email': student.email.trim(),
          'studentCode': student.studentCode.trim().toUpperCase(),
          'phoneNumber': student.phoneNumber?.trim(),
          'faculty': student.faculty,
          'major': student.major,
          'avatarUrl': student.photoBase64,
        },
        token: token,
      );
    } catch (e) {
      debugPrint('Lỗi cập nhật sinh viên qua API: $e');
      rethrow;
    }

    final list = await getStudents();
    final index = list.indexWhere((s) => s.id == student.id || s.studentCode.toUpperCase() == student.studentCode.toUpperCase());
    if (index != -1) {
      list[index] = student;
    } else {
      list.insert(0, student);
    }
    await _saveList(list);
  }

  Future<void> deleteStudent(String id) async {
    final token = await TokenStorage().getToken();

    // Đồng bộ lên API Backend
    try {
      await ApiClient().delete(
        '/students/$id',
        token: token,
      );
    } catch (e) {
      debugPrint('Lỗi xóa sinh viên qua API: $e');
      rethrow;
    }

    final list = await getStudents();
    final cleanGuid = id.trim().toLowerCase();
    list.removeWhere((s) => s.id.toLowerCase() == cleanGuid || s.studentCode.toUpperCase() == id.toUpperCase());
    await _saveList(list);
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
