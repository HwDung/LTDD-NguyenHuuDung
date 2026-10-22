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
      id: 'gv-001',
      lecturerCode: 'GV001',
      fullName: 'ThS. Trần Văn Hùng',
      email: 'hungtv@university.edu.vn',
      department: 'Bộ môn Kỹ thuật phần mềm',
      phoneNumber: '0988776655',
    ),
    LecturerModel(
      id: 'gv-002',
      lecturerCode: 'GV002',
      fullName: 'TS. Nguyễn Thị Lan',
      email: 'lannt@university.edu.vn',
      department: 'Bộ môn Khoa học máy tính',
      phoneNumber: '0911223344',
    ),
    LecturerModel(
      id: 'gv-003',
      lecturerCode: 'GV003',
      fullName: 'PGS. TS. Lê Hoàng Nam',
      email: 'namlh@university.edu.vn',
      department: 'Bộ môn Hệ thống thông tin',
      phoneNumber: '0933445566',
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
      await _apiClient.post(
        '/lecturers',
        body: {
          'username': lecturer.lecturerCode.toLowerCase(),
          'email': lecturer.email,
          'fullName': lecturer.fullName,
          'department': lecturer.department,
          'phoneNumber': lecturer.phoneNumber ?? '',
          'password': 'Password123!',
        },
        token: token,
      );
    } catch (_) {}
  }

  Future<void> updateLecturer(LecturerModel lecturer) async {
    final list = await getLecturers();
    final index = list.indexWhere((l) => l.id == lecturer.id);
    if (index != -1) {
      list[index] = lecturer;
      await _saveList(list);
    }
  }

  Future<void> deleteLecturer(String id) async {
    final list = await getLecturers();
    list.removeWhere((l) => l.id == id);
    await _saveList(list);
  }

  Future<void> _saveList(List<LecturerModel> list) async {
    final jsonString = jsonEncode(list.map((l) => l.toJson()).toList());
    await _storage.write(key: _storageKey, value: jsonString);
  }
}
