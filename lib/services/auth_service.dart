import 'package:nguyenhuudung/core/api_client.dart';
import 'package:nguyenhuudung/core/constants.dart';
import 'package:nguyenhuudung/core/jwt_decoder.dart';
import 'package:nguyenhuudung/core/token_storage.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  // ==================== ĐĂNG NHẬP OTP ====================

  // Bước 1: Gửi username và password để yêu cầu OTP gửi về email.
  Future<Map<String, dynamic>> requestLoginOtp({
    required String username,
    required String password,
  }) async {
    return _apiClient.post(
      ApiConstants.login,
      body: {
        'username': username.trim(),
        'password': password,
      },
    );
  }

  // Bước 2: Xác thực OTP và lưu phiên đăng nhập.
  // LƯU Ý QUAN TRỌNG: Backend Swagger yêu cầu trường tên là 'code' (6 chữ số), không phải 'otp'.
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String username,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.verifyLogin,
      body: {
        'username': username.trim(),
        'code': otp.trim(), // Đã sửa từ 'otp' thành 'code' đúng chuẩn API
      },
    );

    final data = _extractData(response);
    final token = _extractToken(data) ?? _extractToken(response);

    if (token == null || token.isEmpty) {
      throw ApiException(
        'Xác minh OTP thành công nhưng không tìm thấy token. '
        'Hãy kiểm tra cấu trúc response của API.',
      );
    }

    await _tokenStorage.saveToken(token);

    // Trích xuất vai trò (Role), Username, Email từ JWT hoặc response
    String role = _extractRole(data) ?? JwtDecoder.extractRole(token);
    if (role.isEmpty) {
      // Nếu JWT không có claim role rõ ràng, thử gọi dashboard để xác định
      try {
        final dashboardData = await _apiClient.get(ApiConstants.dashboard, token: token);
        role = _extractRole(dashboardData) ?? '';
      } catch (_) {
        // Mặc định vai trò nếu không lấy được
        role = 'Admin';
      }
    }

    if (role.isEmpty) {
      role = 'Admin';
    }

    final decodedUsername = JwtDecoder.extractUsername(token) ?? username;
    final decodedEmail = JwtDecoder.extractEmail(token);
    final decodedUserId = JwtDecoder.extractUserId(token) ??
        (data['userId'] ?? data['id'])?.toString() ??
        (response['userId'] ?? response['id'])?.toString();

    if (decodedUserId != null && decodedUserId.isNotEmpty) {
      await _tokenStorage.saveUserId(decodedUserId);
    }

    await _tokenStorage.saveUserInfo(
      role: role,
      username: decodedUsername,
      email: decodedEmail,
      userId: decodedUserId,
    );

    return {
      'token': token,
      'role': role,
      'username': decodedUsername,
      'response': response,
    };
  }

  // ==================== ĐĂNG KÝ OTP ====================

  // Bước 1: Gửi thông tin đăng ký để yêu cầu OTP.
  // Backend Swagger: username, email, password, fullName (bắt buộc), không gửi confirmPassword.
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? studentCode,
    String? faculty,
    String? major,
    int? enrollmentYear,
  }) async {
    final body = <String, dynamic>{
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
      'fullName': fullName.trim(),
    };

    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      body['phoneNumber'] = phoneNumber.trim();
    }
    if (studentCode != null && studentCode.trim().isNotEmpty) {
      body['studentCode'] = studentCode.trim();
    }
    if (faculty != null && faculty.trim().isNotEmpty) {
      body['faculty'] = faculty.trim();
    }
    if (major != null && major.trim().isNotEmpty) {
      body['major'] = major.trim();
    }
    if (enrollmentYear != null) {
      body['enrollmentYear'] = enrollmentYear;
    }

    return _apiClient.post(
      ApiConstants.register,
      body: body,
    );
  }

  // Bước 2: Xác minh OTP đăng ký.
  // Backend Swagger: { "email": "...", "code": "..." } (6 chữ số)
  Future<Map<String, dynamic>> verifyRegister({
    required String email,
    required String code,
  }) async {
    return _apiClient.post(
      ApiConstants.verifyRegister,
      body: {
        'email': email.trim(),
        'code': code.trim(),
      },
    );
  }

  // ==================== TIỆN ÍCH DỮ LIỆU & TOKEN ====================

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return response;
  }

  String? _extractToken(Map<String, dynamic> data) {
    final directData = data['data'];
    if (directData is String && directData.startsWith('ey')) {
      return directData;
    }

    final token = data['accessToken'] ??
        data['access_token'] ??
        data['token'] ??
        data['jwt'] ??
        data['bearer'];

    if (token != null && token.toString().isNotEmpty) {
      return token.toString();
    }

    if (directData is Map) {
      return _extractToken(Map<String, dynamic>.from(directData));
    }

    return null;
  }

  String? _extractRole(Map<String, dynamic> data) {
    final role = data['role'] ??
        data['roles'] ??
        data['userRole'] ??
        data['user']?['role'];

    if (role is List && role.isNotEmpty) {
      return role.first.toString();
    }
    if (role != null) {
      return role.toString();
    }
    return null;
  }

  Future<String?> getToken() {
    return _tokenStorage.getToken();
  }

  Future<String?> getRole() {
    return _tokenStorage.getRole();
  }

  Future<String?> getUsername() {
    return _tokenStorage.getUsername();
  }

  Future<String?> getStudentCode() {
    return _tokenStorage.getStudentCode();
  }

  Future<String?> getLecturerCode() {
    return _tokenStorage.getLecturerCode();
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }
}
