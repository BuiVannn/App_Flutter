import 'dart:convert';
import 'package:http/http.dart' as http;

/// Ném khi không xác thực được (401 và refresh thất bại).
class ApiUnauthorized implements Exception {
  final String message;
  ApiUnauthorized([this.message = 'Phiên đăng nhập đã hết hạn']);
  @override
  String toString() => message;
}

/// Ném khi server trả lỗi (>=400, khác 401).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP client gọi Dashboard v1: tự gắn Bearer; khi 401 thì refresh rồi thử lại 1 lần.
class DashboardClient {
  DashboardClient({
    required String baseUrl,
    required Future<String?> Function() getAccessToken,
    required Future<String?> Function() refreshToken,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _getAccessToken = getAccessToken,
        _refreshToken = refreshToken,
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final Future<String?> Function() _getAccessToken;
  final Future<String?> Function() _refreshToken;
  final http.Client _http;

  /// GET trả JSON object. `path` bắt đầu bằng '/'.
  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    var token = await _getAccessToken();
    var res = await _http.get(uri, headers: _headers(token));

    if (res.statusCode == 401) {
      final fresh = await _refreshToken();
      if (fresh == null) throw ApiUnauthorized();
      res = await _http.get(uri, headers: _headers(fresh));
      if (res.statusCode == 401) throw ApiUnauthorized();
    }

    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
    final body = jsonDecode(res.body);
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  Map<String, String> _headers(String? token) => {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
}
