import 'dart:convert';

class JwtDecoder {
  /// Giải mã JWT token trả về payload dạng Map
  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};

      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 0:
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        default:
          return {};
      }

      final payloadString = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Trích xuất role từ token (hỗ trợ các chuẩn ASP.NET Core Identity & custom claim)
  static String extractRole(String token) {
    final claims = decode(token);
    final role = claims['role'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
        claims['roles'] ??
        claims['Role'];

    if (role is List && role.isNotEmpty) {
      return role.first.toString();
    }
    if (role != null) {
      return role.toString();
    }
    return '';
  }

  /// Trích xuất username từ token
  static String? extractUsername(String token) {
    final claims = decode(token);
    return (claims['unique_name'] ??
            claims['name'] ??
            claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
            claims['sub'])
        ?.toString();
  }

  /// Trích xuất email từ token
  static String? extractEmail(String token) {
    final claims = decode(token);
    return (claims['email'] ??
            claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'])
        ?.toString();
  }

  /// Trích xuất User ID (GUID) từ token (hỗ trợ nameidentifier, sub, id, userId)
  static String? extractUserId(String token) {
    final claims = decode(token);
    return (claims['nameid'] ??
            claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
            claims['sub'] ??
            claims['userId'] ??
            claims['id'] ??
            claims['studentId'])
        ?.toString();
  }
}
