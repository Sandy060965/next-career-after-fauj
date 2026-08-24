import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'officer_session_token_v1';
const _refreshTokenKey = 'officer_refresh_token_v1';

/// The officer's access and refresh tokens are the app state sensitive
/// enough to warrant OS-level secure storage (Keychain/Keystore) rather
/// than SharedPreferences — everything else the app persists locally is
/// the officer's own career data, not a bearer credential.
class SessionStorage {
  SessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('SessionStorage.readToken failed: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('SessionStorage.saveToken failed: $e');
    }
  }

  Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('SessionStorage.readRefreshToken failed: $e');
      return null;
    }
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      debugPrint('SessionStorage.saveRefreshToken failed: $e');
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('SessionStorage.clearToken failed: $e');
    }
  }
}
