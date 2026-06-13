import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/app_storage.dart';
import 'session_events.dart';

class DioClient {
  DioClient._();
  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.apiTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeoutMs),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _LogInterceptor(),
    ]);
  }
}

/// Attaches Bearer token from storage to every request
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = AppStorage.instance.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 on an authenticated request → token expired/revoked. Clear the session
    // and notify the auth layer so the UI redirects to login. The token guard
    // avoids treating a failed login attempt (no stored token) as a logout.
    if (err.response?.statusCode == 401 &&
        (AppStorage.instance.token?.isNotEmpty ?? false)) {
      AppStorage.instance.clearSession();
      SessionEvents.instance.notifyUnauthorized();
    }
    handler.next(err);
  }
}

/// Simple console log for debug builds
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API ERROR] ${err.response?.statusCode} ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

/// Standardized API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : null,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}
