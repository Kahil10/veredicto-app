import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final String? token;
  const ApiClient({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$kBaseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 20));
      return _parse(res);
    } on TimeoutException {
      throw const ApiException(408, 'El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _parse(res);
    } on TimeoutException {
      throw const ApiException(408, 'El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  Future<dynamic> postForm(String path, Map<String, String> body) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl$path'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));
      return _parse(res);
    } on TimeoutException {
      throw const ApiException(408, 'El servidor tardó demasiado. Inténtalo de nuevo.');
    }
  }

  dynamic _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    String detail = 'Error ${res.statusCode}';
    try {
      detail = jsonDecode(res.body)['detail'] ?? detail;
    } catch (_) {}
    throw ApiException(res.statusCode, detail);
  }
}
