import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'access_token';
  static const String _apiTokenKey = 'api_access_token';
  static const String _roleKey = 'user_role';
  static const String _usernameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _studentCodeKey = 'student_code';
  static const String _lecturerCodeKey = 'lecturer_code';
  static const String _userIdKey = 'user_id';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    // Nếu đây là JWT token hợp lệ của hệ thống backend, lưu vào apiTokenKey
    if (token.startsWith('ey') || token.length > 50) {
      await _storage.write(key: _apiTokenKey, value: token);
    }
  }

  Future<void> saveApiToken(String token) async {
    await _storage.write(key: _apiTokenKey, value: token);
  }

  Future<String?> getApiToken() async {
    return _storage.read(key: _apiTokenKey);
  }

  Future<String?> getToken() async {
    final current = await _storage.read(key: _tokenKey);
    if (current != null && current.startsWith('ey')) {
      return current;
    }
    // Nếu token phiên hiện tại là token giả định (ví dụ sinh viên/giảng viên đăng nhập bằng mã),
    // ưu tiên fallback về apiTokenKey để các request API backend không bị lỗi 401 Unauthorized
    final apiToken = await _storage.read(key: _apiTokenKey);
    if (apiToken != null && apiToken.isNotEmpty) {
      return apiToken;
    }
    return current;
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> getRole() async {
    return _storage.read(key: _roleKey);
  }

  Future<void> saveStudentCode(String code) async {
    await _storage.write(key: _studentCodeKey, value: code);
  }

  Future<String?> getStudentCode() async {
    return _storage.read(key: _studentCodeKey);
  }

  Future<void> saveLecturerCode(String code) async {
    await _storage.write(key: _lecturerCodeKey, value: code);
  }

  Future<String?> getLecturerCode() async {
    return _storage.read(key: _lecturerCodeKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  Future<void> saveUserInfo({
    String? username,
    String? email,
    String? role,
    String? studentCode,
    String? lecturerCode,
    String? userId,
  }) async {
    if (username != null) await _storage.write(key: _usernameKey, value: username);
    if (email != null) await _storage.write(key: _emailKey, value: email);
    if (role != null) await _storage.write(key: _roleKey, value: role);
    if (studentCode != null) await _storage.write(key: _studentCodeKey, value: studentCode);
    if (lecturerCode != null) await _storage.write(key: _lecturerCodeKey, value: lecturerCode);
    if (userId != null) await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUsername() async {
    return _storage.read(key: _usernameKey);
  }

  Future<String?> getEmail() async {
    return _storage.read(key: _emailKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _studentCodeKey);
    await _storage.delete(key: _lecturerCodeKey);
    await _storage.delete(key: _userIdKey);
    // Lưu ý: Không xóa _apiTokenKey để khi Giảng viên / Sinh viên đăng nhập,
    // ứng dụng vẫn giữ token kết nối backend API
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
