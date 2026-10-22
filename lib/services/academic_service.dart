import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nguyenhuudung/core/api_client.dart';
import 'package:nguyenhuudung/core/constants.dart';
import 'package:nguyenhuudung/core/token_storage.dart';
import 'package:nguyenhuudung/models/attendance_model.dart';
import 'package:nguyenhuudung/models/class_session_model.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/enrollment_model.dart';
import 'package:nguyenhuudung/models/faculty_model.dart';
import 'package:nguyenhuudung/models/subject_model.dart';

class AcademicService {
  AcademicService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<String?> _getToken() => _tokenStorage.getToken();

  // ==================== KHOA VÀ NGÀNH HỌC (FACULTIES & MAJORS) ====================
  Future<List<FacultyModel>> getFaculties() async {
    try {
      final res = await _apiClient.get('/faculties');
      final rawList = res['data'];
      if (rawList is List && rawList.isNotEmpty) {
        return rawList.map((item) => FacultyModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (_) {}
    return _getDefaultFaculties();
  }

  Future<List<MajorModel>> getMajors({int? facultyId}) async {
    try {
      final path = facultyId != null ? '/majors?facultyId=$facultyId' : '/majors';
      final res = await _apiClient.get(path);
      final rawList = res['data'];
      if (rawList is List && rawList.isNotEmpty) {
        return rawList.map((item) => MajorModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (_) {}

    final allFaculties = _getDefaultFaculties();
    if (facultyId != null) {
      final faculty = allFaculties.firstWhere((f) => f.id == facultyId, orElse: () => allFaculties.first);
      return faculty.majors;
    }
    return allFaculties.expand((f) => f.majors).toList();
  }

  List<FacultyModel> getDefaultFaculties() => _getDefaultFaculties();

  List<FacultyModel> _getDefaultFaculties() {
    return [
      FacultyModel(
        id: 1,
        code: 'CNTT',
        name: 'Công nghệ thông tin',
        majors: [
          MajorModel(id: 1, code: 'KTPM', name: 'Kỹ thuật phần mềm', facultyId: 1),
          MajorModel(id: 2, code: 'CNTT', name: 'Công nghệ thông tin', facultyId: 1),
          MajorModel(id: 3, code: 'KHMT', name: 'Khoa học máy tính', facultyId: 1),
          MajorModel(id: 4, code: 'ATTT', name: 'An toàn thông tin', facultyId: 1),
          MajorModel(id: 5, code: 'HTTT', name: 'Hệ thống thông tin', facultyId: 1),
        ],
      ),
      FacultyModel(
        id: 2,
        code: 'QTKD',
        name: 'Quản trị kinh doanh',
        majors: [
          MajorModel(id: 6, code: 'QTKD', name: 'Quản trị kinh doanh', facultyId: 2),
          MajorModel(id: 7, code: 'MKT', name: 'Marketing', facultyId: 2),
          MajorModel(id: 8, code: 'KDQT', name: 'Kinh doanh quốc tế', facultyId: 2),
        ],
      ),
      FacultyModel(
        id: 3,
        code: 'TCNH',
        name: 'Tài chính - Ngân hàng',
        majors: [
          MajorModel(id: 9, code: 'TCNH', name: 'Tài chính - Ngân hàng', facultyId: 3),
          MajorModel(id: 10, code: 'KT', name: 'Kế toán', facultyId: 3),
        ],
      ),
      FacultyModel(
        id: 4,
        code: 'DTVT',
        name: 'Điện tử - Viễn thông',
        majors: [
          MajorModel(id: 11, code: 'KTDT', name: 'Kỹ thuật Điện tử', facultyId: 4),
          MajorModel(id: 12, code: 'TDH', name: 'Tự động hóa', facultyId: 4),
        ],
      ),
      FacultyModel(
        id: 5,
        code: 'NN',
        name: 'Ngoại ngữ',
        majors: [
          MajorModel(id: 13, code: 'NNA', name: 'Ngôn ngữ Anh', facultyId: 5),
          MajorModel(id: 14, code: 'NNN', name: 'Ngôn ngữ Nhật', facultyId: 5),
        ],
      ),
    ];
  }

  // ==================== DASHBOARD ====================
  Future<Map<String, dynamic>> getDashboard() async {
    final token = await _getToken();
    return _apiClient.get(ApiConstants.dashboard, token: token);
  }

  // ==================== CRUD MÔN HỌC (SUBJECTS) ====================
  Future<List<SubjectModel>> getSubjects() async {
    final token = await _getToken();
    final res = await _apiClient.get(ApiConstants.subjects, token: token);
    final rawList = res['data'];
    if (rawList is List) {
      return rawList.map((item) => SubjectModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createSubject(SubjectModel subject) async {
    final token = await _getToken();
    return _apiClient.post(
      ApiConstants.subjects,
      body: subject.toJson(includeId: false),
      token: token,
    );
  }

  Future<Map<String, dynamic>> updateSubject(int id, SubjectModel subject) async {
    final token = await _getToken();
    return _apiClient.put(
      ApiConstants.subjectById(id),
      body: subject.toJson(includeId: true),
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteSubject(int id) async {
    final token = await _getToken();
    return _apiClient.delete(ApiConstants.subjectById(id), token: token);
  }

  // ==================== CRUD LỚP HỌC PHẦN (COURSE CLASSES) ====================
  static const String _classesCacheKey = 'cached_course_classes_list';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final List<CourseClassModel> _defaultClasses = [
    CourseClassModel(
      id: 1,
      code: 'PRN231',
      subjectId: 1,
      lecturerId: 'gv-001',
      lecturerCode: 'GV001',
      lecturerName: 'ThS. Trần Văn Hùng',
      semester: 'Học kỳ 1 (2026)',
      academicYear: 2026,
      capacity: 50,
      subject: SubjectModel(id: 1, code: 'PRN231', name: 'Lập trình ứng dụng di động nâng cao', credits: 3),
    ),
    CourseClassModel(
      id: 2,
      code: 'SWP391',
      subjectId: 2,
      lecturerId: 'gv-002',
      lecturerCode: 'GV002',
      lecturerName: 'TS. Nguyễn Thị Lan',
      semester: 'Học kỳ 1 (2026)',
      academicYear: 2026,
      capacity: 45,
      subject: SubjectModel(id: 2, code: 'SWP391', name: 'Đồ án phát triển phần mềm', credits: 4),
    ),
    CourseClassModel(
      id: 3,
      code: 'PRM392',
      subjectId: 3,
      lecturerId: 'gv-001',
      lecturerCode: 'GV001',
      lecturerName: 'ThS. Trần Văn Hùng',
      semester: 'Học kỳ 2 (2026)',
      academicYear: 2026,
      capacity: 40,
      subject: SubjectModel(id: 3, code: 'PRM392', name: 'Phát triển ứng dụng di động Flutter', credits: 3),
    ),
  ];

  Future<void> _saveClassesCache(List<CourseClassModel> list) async {
    try {
      final jsonStr = jsonEncode(list.map((c) => c.toJson()).toList());
      await _storage.write(key: _classesCacheKey, value: jsonStr);
    } catch (_) {}
  }

  Future<List<CourseClassModel>> getCourseClasses() async {
    try {
      final token = await _getToken();
      final res = await _apiClient.get(ApiConstants.courseClasses, token: token);
      final rawList = res['data'];
      if (rawList is List && rawList.isNotEmpty) {
        final list = rawList.map((item) => CourseClassModel.fromJson(Map<String, dynamic>.from(item))).toList();
        await _saveClassesCache(list);
        return list;
      }
    } catch (_) {}

    // Fallback: Đọc từ bộ nhớ đệm an toàn
    try {
      final rawCache = await _storage.read(key: _classesCacheKey);
      if (rawCache != null && rawCache.isNotEmpty) {
        final list = (jsonDecode(rawCache) as List)
            .map((item) => CourseClassModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    // Fallback cuối cùng: Danh sách lớp mẫu
    await _saveClassesCache(_defaultClasses);
    return _defaultClasses;
  }

  Future<Map<String, dynamic>> createCourseClass(CourseClassModel courseClass) async {
    final token = await _getToken();
    Map<String, dynamic> result = {};
    try {
      result = await _apiClient.post(
        ApiConstants.courseClasses,
        body: courseClass.toJson(includeId: false),
        token: token,
      );
    } catch (_) {}

    // Đồng bộ vào cache
    try {
      final currentList = await getCourseClasses();
      currentList.insert(0, courseClass);
      await _saveClassesCache(currentList);
    } catch (_) {}

    return result;
  }

  Future<Map<String, dynamic>> updateCourseClass(int id, CourseClassModel courseClass) async {
    final token = await _getToken();
    Map<String, dynamic> result = {};
    try {
      result = await _apiClient.put(
        ApiConstants.courseClassById(id),
        body: courseClass.toJson(includeId: true),
        token: token,
      );
    } catch (_) {}

    // Cập nhật vào cache
    try {
      final currentList = await getCourseClasses();
      final idx = currentList.indexWhere((c) => c.id == id);
      if (idx != -1) {
        currentList[idx] = courseClass;
        await _saveClassesCache(currentList);
      }
    } catch (_) {}

    return result;
  }

  Future<Map<String, dynamic>> deleteCourseClass(int id) async {
    final token = await _getToken();
    Map<String, dynamic> result = {};
    try {
      result = await _apiClient.delete(ApiConstants.courseClassById(id), token: token);
    } catch (_) {}

    // Xóa khỏi cache
    try {
      final currentList = await getCourseClasses();
      currentList.removeWhere((c) => c.id == id);
      await _saveClassesCache(currentList);
    } catch (_) {}

    return result;
  }

  // ==================== CRUD BUỔI HỌC (CLASS SESSIONS) ====================
  Future<List<ClassSessionModel>> getSessionsByCourseClass(int courseClassId) async {
    final token = await _getToken();
    final res = await _apiClient.get(ApiConstants.sessionsByCourseClass(courseClassId), token: token);
    final rawList = res['data'];
    if (rawList is List) {
      return rawList.map((item) => ClassSessionModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createSession(int courseClassId, ClassSessionModel session) async {
    final token = await _getToken();
    return _apiClient.post(
      ApiConstants.sessionsByCourseClass(courseClassId),
      body: session.toJson(includeId: false),
      token: token,
    );
  }

  Future<Map<String, dynamic>> updateSession(int id, ClassSessionModel session) async {
    final token = await _getToken();
    return _apiClient.put(
      ApiConstants.sessionById(id),
      body: session.toJson(includeId: true),
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteSession(int id) async {
    final token = await _getToken();
    return _apiClient.delete(ApiConstants.sessionById(id), token: token);
  }

  // ==================== CRUD ĐIỂM DANH (ATTENDANCE) ====================
  Future<List<AttendanceModel>> getAttendanceBySession(int sessionId) async {
    final token = await _getToken();
    final res = await _apiClient.get(ApiConstants.attendanceBySession(sessionId), token: token);
    final rawList = res['data'];
    if (rawList is List) {
      return rawList.map((item) => AttendanceModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> markAttendance(AttendanceModel attendance) async {
    final token = await _getToken();
    return _apiClient.post(
      ApiConstants.attendance,
      body: attendance.toJson(includeId: false),
      token: token,
    );
  }

  Future<Map<String, dynamic>> updateAttendance(int id, AttendanceModel attendance) async {
    final token = await _getToken();
    return _apiClient.put(
      ApiConstants.attendanceById(id),
      body: attendance.toJson(includeId: true),
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteAttendance(int id) async {
    final token = await _getToken();
    return _apiClient.delete(ApiConstants.attendanceById(id), token: token);
  }

  // ==================== CRUD ĐĂNG KÝ HỌC (ENROLLMENTS) ====================
  Future<List<EnrollmentModel>> getEnrollments() async {
    final token = await _getToken();
    final res = await _apiClient.get(ApiConstants.enrollments, token: token);
    final rawList = res['data'];
    if (rawList is List) {
      return rawList.map((item) => EnrollmentModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createEnrollment(EnrollmentModel enrollment) async {
    final token = await _getToken();
    return _apiClient.post(
      ApiConstants.enrollments,
      body: enrollment.toJson(includeId: false),
      token: token,
    );
  }

  Future<Map<String, dynamic>> updateEnrollment(int id, EnrollmentModel enrollment) async {
    final token = await _getToken();
    return _apiClient.put(
      ApiConstants.enrollmentById(id),
      body: enrollment.toJson(includeId: true),
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteEnrollment(int id) async {
    final token = await _getToken();
    return _apiClient.delete(ApiConstants.enrollmentById(id), token: token);
  }
}
