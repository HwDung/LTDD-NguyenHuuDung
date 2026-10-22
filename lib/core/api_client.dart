import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    final value = dotenv.env['API_BASE_URL']?.trim();

    if (value == null || value.isEmpty) {
      throw ApiException(
        'Chưa cấu hình API_BASE_URL trong file .env',
      );
    }

    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Chỉ gửi Authorization Bearer nếu token là JWT hợp lệ từ máy chủ (có cấu trúc phần ngăn cách bởi dấu chấm)
    if (token != null &&
        token.isNotEmpty &&
        token.contains('.') &&
        !token.startsWith('student_token_') &&
        !token.startsWith('lecturer_token_') &&
        !token.startsWith('admin_token_')) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
  }) async {
    try {
      final response = await _client
          .get(
            _buildUri(path),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 25));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu.');
    } on http.ClientException {
      throw ApiException('Không thể kết nối đến máy chủ API.');
    } catch (e) {
      throw ApiException('Lỗi khi gửi yêu cầu: $e');
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUri(path),
            headers: _buildHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu.');
    } on http.ClientException {
      throw ApiException('Không thể kết nối đến máy chủ API.');
    } catch (e) {
      throw ApiException('Lỗi khi gửi yêu cầu: $e');
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final response = await _client
          .put(
            _buildUri(path),
            headers: _buildHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu.');
    } on http.ClientException {
      throw ApiException('Không thể kết nối đến máy chủ API.');
    } catch (e) {
      throw ApiException('Lỗi khi gửi yêu cầu: $e');
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
  }) async {
    try {
      final response = await _client
          .delete(
            _buildUri(path),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 25));

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu.');
    } on http.ClientException {
      throw ApiException('Không thể kết nối đến máy chủ API.');
    } catch (e) {
      throw ApiException('Lỗi khi gửi yêu cầu: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final responseBody = response.body.trim();
    dynamic decodedBody;

    if (responseBody.isNotEmpty) {
      try {
        decodedBody = jsonDecode(responseBody);
      } on FormatException {
        decodedBody = responseBody;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedBody == null) {
        return <String, dynamic>{'success': true};
      }

      if (decodedBody is Map) {
        return Map<String, dynamic>.from(decodedBody);
      }

      if (decodedBody is List) {
        return <String, dynamic>{'data': decodedBody};
      }

      return <String, dynamic>{'data': decodedBody, 'message': decodedBody.toString()};
    }

    throw ApiException(
      _extractErrorMessage(decodedBody, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(dynamic body, int statusCode) {
    if (body is List) {
      return body.map((e) => _translateErrorMessage(e.toString())).join('\n');
    }

    if (body is Map) {
      final message = body['message'] ?? body['error'] ?? body['title'] ?? body['detail'];

      final errors = body['errors'];
      if (errors is Map) {
        final errorList = <String>[];
        for (final entry in errors.entries) {
          if (entry.value is List) {
            errorList.addAll((entry.value as List).map((e) => _translateErrorMessage(e.toString())));
          } else if (entry.value != null) {
            errorList.add(_translateErrorMessage(entry.value.toString()));
          }
        }
        if (errorList.isNotEmpty) {
          return errorList.join('\n');
        }
      }

      if (message != null) {
        return _translateErrorMessage(message.toString());
      }
    }

    if (body is String && body.isNotEmpty) {
      return _translateErrorMessage(body);
    }

    return 'Yêu cầu thất bại (HTTP $statusCode).';
  }

  String _translateErrorMessage(String message) {
    if (message.contains('non alphanumeric character')) {
      return 'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt (!@#\$%^&*...).';
    }
    if (message.contains("uppercase ('A'-'Z')") || message.contains('uppercase')) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ in hoa (A-Z).';
    }
    if (message.contains("lowercase ('a'-'z')") || message.contains('lowercase')) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ thường (a-z).';
    }
    if (message.contains("digit ('0'-'9')") || message.contains('digit')) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ số (0-9).';
    }
    if (message.contains('not a valid e-mail address')) {
      return 'Địa chỉ email không đúng định dạng.';
    }
    if (message.contains('tồn tại') || message.contains('already exists')) {
      return 'Tên đăng nhập hoặc email này đã tồn tại trong hệ thống.';
    }
    return message;
  }

  void close() {
    _client.close();
  }
}
