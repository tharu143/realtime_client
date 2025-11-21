import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract interface for handling authentication tokens.
///
/// Implement this interface to provide custom token management logic.
/// The default implementation [SecureStorageAuthDelegate] uses
/// [FlutterSecureStorage] for secure token persistence.
abstract class AuthDelegate {
  /// Retrieves the current access token.
  ///
  /// Returns `null` if no token is available.
  Future<String?> getAccessToken();

  /// Refreshes the access token when it expires.
  ///
  /// This method is called automatically when a 401 error is received.
  Future<void> refreshAccessToken();

  /// Saves a new access token securely.
  ///
  /// The [token] parameter contains the new access token to store.
  Future<void> saveAccessToken(String token);

  /// Clears the stored access token.
  ///
  /// This is typically called during logout.
  Future<void> clearToken();
}

/// Default implementation of [AuthDelegate] using secure storage.
///
/// This implementation uses [FlutterSecureStorage] to securely store
/// authentication tokens on the device.
///
/// Example:
/// ```dart
/// final authDelegate = SecureStorageAuthDelegate(
///   refreshTokenCallback: () async {
///     // Call your refresh token API
///     final response = await http.post('/auth/refresh');
///     return response.body['access_token'];
///   },
/// );
/// ```
class SecureStorageAuthDelegate implements AuthDelegate {
  final FlutterSecureStorage _storage;
  final String _tokenKey;
  final Future<String?> Function()? _refreshTokenCallback;

  /// Creates a new [SecureStorageAuthDelegate].
  ///
  /// - [storage]: Optional custom [FlutterSecureStorage] instance
  /// - [tokenKey]: Key used to store the token (default: 'auth_token')
  /// - [refreshTokenCallback]: Optional callback to refresh expired tokens
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
