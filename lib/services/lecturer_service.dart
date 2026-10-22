import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nguyenhuudung/core/api_client.dart';
import 'package:nguyenhuudung/core/token_storage.dart';
import 'package:nguyenhuudung/models/lecturer_model.dart';

class LecturerService {
  LecturerService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  static const String _storageKey = 'managed_lecturers_list';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final List<LecturerModel> _initialLecturers = [
    LecturerModel(
      id: 'e9966800-bf60-4b28-adfa-08df2fafa03f',
      lecturerCode: 'GV000001',
      fullName: 'ThS. Nguyễn Văn An',
      email: 'nguyenvanan@gmail.com',
      department: 'Công nghệ phần mềm',
      phoneNumber: '0901234567',
    ),
    LecturerModel(
      id: '10ba0011-2411-4c51-adfb-08df2fafa03f',
      lecturerCode: 'GV000002',
      fullName: 'TS. Trần Thị Bình',
      email: 'tranthibinh@gmail.com',
      department: 'Hệ thống thông tin',
      phoneNumber: '0901234567',
    ),
    LecturerModel(
      id: '89851f6f-a48b-477e-adfc-08df2fafa03f',
      lecturerCode: 'GV000003',
      fullName: 'ThS. Lê Hoàng Cường',
      email: 'lehoangcuong@gmail.com',
      department: 'Mạng máy tính & An ninh',
      phoneNumber: '0901234567',
    ),
  ];

  Future<List<LecturerModel>> getLecturers() async {
    // 1. Thử lấy dữ liệu mới nhất từ backend API
    try {
      final token = await TokenStorage().getToken();
      final res = await _apiClient.get('/lecturers', token: token);
      final rawList = res['data'];
      if (rawList is List && rawList.isNotEmpty) {
        final list = rawList.map((item) => LecturerModel.fromJson(Map<String, dynamic>.from(item))).toList();
        await _saveList(list);
        return list;
      }
    } catch (_) {}

    // 2. Fallback: Lấy từ cache
    final rawJson = await _storage.read(key: _storageKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final list = (jsonDecode(rawJson) as List)
            .map((item) => LecturerModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    await _saveList(_initialLecturers);
    return _initialLecturers;
  }

  Future<LecturerModel?> findByCode(String code) async {
    final list = await getLecturers();
    final normalized = code.trim().toUpperCase();
    try {
      return list.firstWhere(
        (l) =>
            l.lecturerCode.trim().toUpperCase() == normalized ||
            l.id.trim().toUpperCase() == normalized ||
            (l.id.isNotEmpty && normalized.contains(l.id.toUpperCase())) ||
            (l.lecturerCode.isNotEmpty && normalized.contains(l.lecturerCode.toUpperCase())),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> createLecturer(LecturerModel lecturer) async {
    final list = await getLecturers();
    list.insert(0, lecturer);
    await _saveList(list);

    // Đồng bộ lên backend API
    try {
      final token = await TokenStorage().getToken();
      final username = lecturer.lecturerCode.isNotEmpty
          ? lecturer.lecturerCode.toLowerCase()
          : (lecturer.email.contains('@') ? lecturer.email.split('@').first : 'gv_${DateTime.now().millisecondsSinceEpoch}');
      await _apiClient.post(
        '/lecturers',
        body: {
          'username': username,
          'email': lecturer.email,
          'fullName': lecturer.fullName,
          'department': lecturer.department,
          'phoneNumber': lecturer.phoneNumber ?? '',
          'password': 'Lecturer@123',
        },
        token: token,
      );
    } catch (_) {}
  }

  Future<void> updateLecturer(LecturerModel lecturer) async {
    final list = await getLecturers();
    final index = list.indexWhere((l) => l.id == lecturer.id || l.lecturerCode.toUpperCase() == lecturer.lecturerCode.toUpperCase());
    if (index != -1) {
      list[index] = lecturer;
      await _saveList(list);
    }

    // Đồng bộ lên backend API
    try {
      final token = await TokenStorage().getToken();
      final identifier = lecturer.lecturerCode.isNotEmpty ? lecturer.lecturerCode : lecturer.id;
      await _apiClient.put(
        '/lecturers/$identifier',
        body: {
          'fullName': lecturer.fullName,
          'email': lecturer.email,
          'phoneNumber': lecturer.phoneNumber ?? '',
          'department': lecturer.department,
        },
        token: token,
      );
    } catch (_) {}
  }

  Future<void> deleteLecturer(String id) async {
    final list = await getLecturers();
    list.removeWhere((l) => l.id == id || l.lecturerCode.toUpperCase() == id.toUpperCase());
    await _saveList(list);

    // Đồng bộ lên backend API
    try {
      final token = await TokenStorage().getToken();
      await _apiClient.delete(
        '/lecturers/$id',
        token: token,
      );
    } catch (_) {}
  }

  Future<void> _saveList(List<LecturerModel> list) async {
    final jsonString = jsonEncode(list.map((l) => l.toJson()).toList());
    await _storage.write(key: _storageKey, value: jsonString);
  }
}
