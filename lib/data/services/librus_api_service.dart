import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'librus_auth_service.dart';

class LibrusApiService {
  static const String _directApiBase = 'https://api.librus.pl/2.0';
  static const String _webProxyBase = '/api/librus/2.0';

  final LibrusAuthService _authService;
  final http.Client _client;

  LibrusApiService({
    required LibrusAuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? http.Client();

  String get _baseUrl => kIsWeb ? _webProxyBase : _directApiBase;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getSavedToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Accept': 'application/json',
    };
  }

  Future<dynamic> getEndpoint(String endpoint) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final response = await _client.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Librus API error (${response.statusCode}): ${response.body}');
    }
  }
}
