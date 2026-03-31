import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_repository.dart';
import '../models/auth_response.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  static const _tokenKey = 'jwt_access_token';
  static const _roleKey = 'user_role';

  final AuthRepository _authRepository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  String? _role;
  bool _sessionResolving = false;

  String? get token => _token;
  String? get role => _role;

  /// Dok je true, čeka se potvrda sesije sa serverom (samo ako postoji sačuvan token).
  bool get isSessionResolving => _sessionResolving;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _role == 'ADMIN';
  bool get isStudent => _role == 'STUDENT';

  Future<String?> _storageRead(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return _storage.read(key: key);
  }

  Future<void> _storageWrite(String key, String? value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      if (value == null || value.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
      return;
    }

    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<void> _storageDelete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    await _storage.delete(key: key);
  }

  /// Samo čitanje sa diska — brzo, bez mreže. Pozovi `validateStoredSession()` posle prvog frejma.
  Future<void> loadFromStorage() async {
    _token = await _storageRead(_tokenKey);
    _role = await _storageRead(_roleKey);
    _sessionResolving = _token != null && _token!.isNotEmpty;
    notifyListeners();
  }

  /// Provera JWT-a na `/auth/me` sa timeout-om. Ne blokira `runApp` ako se pozove bez await iz main-a.
  Future<void> validateStoredSession() async {
    if (_token == null || _token!.isEmpty) {
      _sessionResolving = false;
      notifyListeners();
      return;
    }
    _sessionResolving = true;
    notifyListeners();
    try {
      final me = await _authRepository
          .fetchMe(accessToken: _token!)
          .timeout(const Duration(seconds: 12));
      _role = me.role;
      await _storage.write(key: _roleKey, value: _role);
    } on TimeoutException {
      _token = null;
      _role = null;
      await _persistToken(null);
      await _storage.delete(key: _roleKey);
    } catch (_) {
      _token = null;
      _role = null;
      await _persistToken(null);
      await _storage.delete(key: _roleKey);
    } finally {
      _sessionResolving = false;
      notifyListeners();
    }
  }

  Future<void> _persistToken(String? value) async {
    await _storageWrite(_tokenKey, value);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _authRepository.login(email: email, password: password);
    _token = res.accessToken;
    _role = res.role;
    await _persistToken(_token);
    await _storageWrite(_roleKey, _role);
    notifyListeners();
    return res;
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    await _persistToken(null);
    await _storageDelete(_roleKey);
    notifyListeners();
  }

  Future<String?> getToken() async {
    return _token ?? await _storageRead(_tokenKey);
  }
}
