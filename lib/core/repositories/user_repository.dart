// ignore_for_file: use_null_aware_elements
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(ref.read(apiClientProvider)));

class UserRepository {
  final ApiClient _api;
  UserRepository(this._api);

  Future<List<UserModel>> getUsers() async {
    final resp = await _api.get('/users');
    final list = resp.data['data'] as List;
    return list.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String role,
  }) async {
    final resp = await _api.post('/users', data: {
      'name': name,
      'email': email,
      'role': role,
    });
    return _fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateUser(String id, {String? name, String? role, String? status}) async {
    final resp = await _api.put('/users/$id', data: {
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
    });
    return _fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/users/$id');
  }

  Future<UserModel> updateProfile({String? name}) async {
    final resp = await _api.put('/users/profile', data: {
      if (name != null) 'name': name,
    });
    return _fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.post('/users/profile/password', data: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPassword,
    });
  }

  Future<void> deleteProfile() async {
    await _api.delete('/users/profile');
  }

  UserModel _fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: j['id'].toString(),
      tenantId: j['tenant_id']?.toString() ?? '',
      role: _parseRole(j['role']),
      name: j['name'] ?? '',
      email: j['email'] ?? '',
      emailVerified: j['email_verified_at'] != null,
      status: j['status'] == 'active' ? UserStatus.active : UserStatus.inactive,
    );
  }

  UserRole _parseRole(String? r) {
    switch (r) {
      case 'owner': return UserRole.owner;
      case 'admin': return UserRole.admin;
      default: return UserRole.cashier;
    }
  }
}
