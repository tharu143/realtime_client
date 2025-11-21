import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthDelegate {
  Future<String?> getAccessToken();
  Future<void> refreshAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> clearToken();
}

class SecureStorageAuthDelegate implements AuthDelegate {
  final FlutterSecureStorage _storage;
  final String _tokenKey;
  final Future<String?> Function()? _refreshTokenCallback;

  SecureStorageAuthDelegate({
    FlutterSecureStorage? storage,
    String tokenKey = 'auth_token',
    Future<String?> Function()? refreshTokenCallback,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _tokenKey = tokenKey,
        _refreshTokenCallback = refreshTokenCallback;

  @override
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  @override
  Future<void> refreshAccessToken() async {
    if (_refreshTokenCallback != null) {
      final newToken = await _refreshTokenCallback!();
      if (newToken != null) {
        await saveAccessToken(newToken);
      }
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
