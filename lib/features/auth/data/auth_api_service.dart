import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_model.dart';

/// Handles semua API call ke /api/auth/*
class AuthApiService {
  static Dio get _dio => DioClient.instance.dio;

  // ── POST /api/auth/login ──────────────────────
  static Future<AuthApiResult> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (res.data['success'] == true) {
        return AuthApiResult.success(
          token: res.data['data']['token'],
          user: UserModel.fromJson(res.data['data']['user']),
        );
      }
      return AuthApiResult.error(res.data['message'] ?? 'Login gagal');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ── POST /api/auth/register ───────────────────
  static Future<AuthApiResult> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      if (res.data['success'] == true) {
        return AuthApiResult.registered(email: email);
      }
      return AuthApiResult.error(res.data['message'] ?? 'Registrasi gagal');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ── POST /api/auth/forgot-password ───────────
  static Future<AuthApiResult> forgotPassword(String email) async {
    try {
      final res = await _dio.post('/auth/forgot-password', data: {
        'email': email,
      });
      if (res.data['success'] == true) {
        return AuthApiResult.success(message: res.data['message']);
      }
      return AuthApiResult.error(res.data['message'] ?? 'Gagal kirim email');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ── POST /api/auth/resend-verification ───────
  static Future<AuthApiResult> resendVerification(String email) async {
    try {
      final res = await _dio.post('/auth/resend-verification', data: {
        'email': email,
      });
      if (res.data['success'] == true) {
        return AuthApiResult.success(message: res.data['message']);
      }
      return AuthApiResult.error(res.data['message'] ?? 'Gagal kirim ulang');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ── POST /api/auth/logout ─────────────────────
  static Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
  }

  // ── GET /api/auth/me ──────────────────────────
  static Future<UserModel?> me() async {
    try {
      final res = await _dio.get('/auth/me');
      if (res.data['success'] == true) {
        return UserModel.fromJson(res.data['data']);
      }
    } catch (_) {}
    return null;
  }

  // ── Error handler ─────────────────────────────
  static AuthApiResult _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      // Validation errors
      if (e.response!.statusCode == 422) {
        final errors = data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstField = errors.values.first;
          final msg = firstField is List ? firstField.first : firstField.toString();
          return AuthApiResult.error(msg);
        }
      }
      // Email not verified
      if (e.response!.statusCode == 403 &&
          data['errors']?['email_unverified'] == true) {
        return AuthApiResult.emailUnverified(
          email: data['errors']['email'] ?? '',
        );
      }
      return AuthApiResult.error(data['message'] ?? 'Terjadi kesalahan');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return AuthApiResult.error(
        'Tidak dapat terhubung ke server. Pastikan backend berjalan di localhost:8000.',
      );
    }
    return AuthApiResult.error('Error: ${e.message}');
  }
}

// ── Result model ──────────────────────────────────
enum AuthApiStatus {
  success,
  registered,   // register berhasil → perlu verifikasi email
  emailUnverified,
  error,
}

class AuthApiResult {
  final AuthApiStatus status;
  final String? token;
  final UserModel? user;
  final String? message;
  final String? email;

  const AuthApiResult._({
    required this.status,
    this.token,
    this.user,
    this.message,
    this.email,
  });

  factory AuthApiResult.success({String? token, UserModel? user, String? message}) =>
      AuthApiResult._(status: AuthApiStatus.success, token: token, user: user, message: message);

  factory AuthApiResult.registered({required String email}) =>
      AuthApiResult._(status: AuthApiStatus.registered, email: email);

  factory AuthApiResult.emailUnverified({required String email}) =>
      AuthApiResult._(status: AuthApiStatus.emailUnverified, email: email);

  factory AuthApiResult.error(String message) =>
      AuthApiResult._(status: AuthApiStatus.error, message: message);

  bool get isSuccess => status == AuthApiStatus.success;
  bool get isRegistered => status == AuthApiStatus.registered;
  bool get isEmailUnverified => status == AuthApiStatus.emailUnverified;
  bool get isError => status == AuthApiStatus.error;
}
