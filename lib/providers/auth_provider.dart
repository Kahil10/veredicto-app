import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';

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
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    if (_token != null) await _fetchMe();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      await _fetchMe();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
  }
}
