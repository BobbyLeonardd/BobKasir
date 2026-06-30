// ignore_for_file: use_null_aware_elements
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.read(apiClientProvider)));

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = resp.data as Map<String, dynamic>;
    await _api.saveTokens(data['token'], data['refresh_token']);
    return data;
  }

  Future<Map<String, dynamic>> googleAuth(String idToken, {String? shopName}) async {
    final resp = await _api.post('/auth/google', data: {
      'id_token': idToken,
      if (shopName != null) 'shop_name': shopName,
    });
    final data = resp.data as Map<String, dynamic>;
    if (data['token'] != null) {
      await _api.saveTokens(data['token'], data['refresh_token']);
    }
    return data;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    await _api.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'shop_name': shopName,
      if (shopAddress != null) 'shop_address': shopAddress,
      if (shopPhone != null) 'shop_phone': shopPhone,
    });
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _api.clearTokens();
    }
  }

  Future<void> sendVerification(String email) async {
    await _api.post('/auth/resend-verification', data: {'email': email});
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    final resp = await _api.post('/auth/verify-email', data: {
      'email': email,
      'otp': otp,
    });
    final data = resp.data as Map<String, dynamic>;
    await _api.saveTokens(data['token'], data['refresh_token']);
    return data;
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword(String email, String otp, String password) async {
    await _api.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'password': password,
    });
  }

  Future<UserModel> getProfile() async {
    final resp = await _api.get('/users/profile');
    return _userFromJson(resp.data['data']);
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }

  UserModel _userFromJson(Map<String, dynamic> j) {
    final tenantData = j['tenant'] as Map<String, dynamic>?;
    return UserModel(
      id: j['id'].toString(),
      tenantId: j['tenant_id']?.toString() ?? '',
      role: _parseRole(j['role']),
      name: j['name'],
      email: j['email'],
      emailVerified: j['email_verified_at'] != null,
      status: j['status'] == 'active' ? UserStatus.active : UserStatus.inactive,
      tenant: tenantData != null ? TenantInfo.fromJson(tenantData) : null,
    );
  }

  UserRole _parseRole(String? r) {
    switch (r) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.cashier;
    }
  }
}
