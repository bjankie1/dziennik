import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LibrusAuthService {
  static const String _tokenKey = 'librus_access_token';
  static const String _refreshTokenKey = 'librus_refresh_token';
  static const String _clientId = '46';

  // Base endpoint or Firebase Cloud Function proxy for Flutter Web
  static const String directOAuthUrl = 'https://api.librus.pl/OAuth/Authorization';
  static const String directGrantUrl = 'https://api.librus.pl/OAuth/Authorization/Grant';
  static const String webProxyUrl = '/api/librus/oauth'; // configured via firebase.json rewrites

  final FlutterSecureStorage _storage;
  final http.Client _client;

  LibrusAuthService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  Future<String?> getSavedToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final url = kIsWeb
          ? Uri.parse(webProxyUrl)
          : Uri.parse('$directGrantUrl?client_id=$_clientId');

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'login',
          'login': username,
          'pass': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('access_token')) {
          await _storage.write(key: _tokenKey, value: data['access_token']);
          if (data.containsKey('refresh_token')) {
            await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Librus login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
