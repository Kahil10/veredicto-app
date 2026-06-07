import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';
import '../services/notifications_service.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class AuthProvider extends ChangeNotifier {
  String? _token;
  UserModel? _user;
  bool _loading = false;
  String? _error;

  String? get token => _token;
  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    _token = await _storage.read(key: 'jwt_token');
    if (_token != null) {
      await _fetchMe();
      if (_token != null) {
        NotificationsService.registerWithAuth(_token!).ignore();
      }
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient().postForm(
        '/auth/login',
        {'username': username, 'password': password},
      );
      _token = data['access_token'];
      await _storage.write(key: 'jwt_token', value: _token!);
      await _fetchMe();
      if (_token != null) {
        NotificationsService.registerWithAuth(_token!).ignore();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password, String? email) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiClient().post('/auth/register', {
        'username': username,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      return await login(username, password);
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchMe() async {
    try {
      final data = await ApiClient(token: _token).get('/api/users/me');
      _user = UserModel.fromJson(data);
    } catch (_) {
      _token = null;
      await _storage.delete(key: 'jwt_token');
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try { await NotificationsService.unregisterToken(_token!); } catch (_) {}
      try { await ApiClient(token: _token).post('/auth/logout', {}); } catch (_) {}
    }
    _token = null;
    _user = null;
    await _storage.delete(key: 'jwt_token');
    notifyListeners();
  }
}
