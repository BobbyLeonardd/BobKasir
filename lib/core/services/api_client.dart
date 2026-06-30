import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Config ──────────────────────────────────────────────────────────────────
// Change this to your Laragon IP when using a physical device.
// Use 10.0.2.2 for Android emulator, localhost for iOS simulator.
const String kBaseUrl = 'http://10.0.2.2/bobkasir/backend/public/api';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

const _kTokenKey = 'access_token';
const _kRefreshTokenKey = 'refresh_token';

// ─── Provider ────────────────────────────────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// ─── ApiClient ───────────────────────────────────────────────────────────────
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _kTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Auto-refresh on 401
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: _kRefreshTokenKey);
      if (refreshToken != null) {
        try {
          final resp = await Dio().post(
            '$kBaseUrl/auth/refresh',
            options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
          );
          final newToken = resp.data['token'];
          final newRefresh = resp.data['refresh_token'];
          await saveTokens(newToken, newRefresh);

          // Retry original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retried = await _dio.fetch(opts);
          return handler.resolve(retried);
        } catch (_) {
          await clearTokens();
        }
      }
    }
    handler.next(err);
  }

  // ── Token helpers ──────────────────────────────────────────────────────────
  Future<void> saveTokens(String token, String refreshToken) async {
    await _storage.write(key: _kTokenKey, value: token);
    await _storage.write(key: _kRefreshTokenKey, value: refreshToken);
  }

  Future<String?> getToken() => _storage.read(key: _kTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────
  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postForm(String path, FormData data) =>
      _dio.post(path, data: data);

  Future<Response> putForm(String path, FormData data) =>
      _dio.put(path, data: data);

  /// Parse API error message from DioException
  static String parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'Terjadi kesalahan.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Koneksi timeout. Periksa jaringan Anda.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Tidak dapat terhubung ke server.';
      }
    }
    return 'Terjadi kesalahan.';
  }
}
