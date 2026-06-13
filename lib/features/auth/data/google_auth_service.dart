import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_model.dart';

/// Google Sign-In service untuk BobKasir.
/// 
/// Flow:
/// 1. User tap "Login dengan Google"
/// 2. Flutter → Google Sign-In SDK → Google Account Picker
/// 3. Dapatkan access_token dari Google
/// 4. Kirim access_token ke backend POST /api/auth/google
/// 5. Backend validasi token via Google API + buat/update user
/// 6. Backend return Sanctum token + user data
/// 7. Flutter simpan token ke AppStorage
class GoogleAuthService {
  // Web Client ID dari Firebase Console → Authentication → Google Sign-in provider
  // Digunakan untuk mendapatkan idToken yang dikirim ke backend Laravel
  static const String _serverClientId =
      '459189186719-dbd1ic4hj4af2emtarc12etb0qm33dhh.apps.googleusercontent.com';
  static const List<String> _scopes = ['email', 'profile'];

  static bool _initialized = false;

  /// Inisialisasi singleton GoogleSignIn (wajib sebelum method lain di v7+).
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Sign in dengan Google dan kirim token ke backend
  static Future<GoogleAuthResult> signIn() async {
    try {
      await _ensureInitialized();
      final googleSignIn = GoogleSignIn.instance;

      if (!googleSignIn.supportsAuthenticate()) {
        return GoogleAuthResult.error(
          'Login Google tidak didukung di platform ini',
        );
      }

      // 1. Sign out dulu untuk force account picker
      await googleSignIn.signOut();

      // 2. Authentication step → idToken
      final GoogleSignInAccount account =
          await googleSignIn.authenticate(scopeHint: _scopes);

      final String? idToken = account.authentication.idToken;

      // 3. Authorization step → accessToken (terpisah dari auth di v7).
      //    authorizeScopes melempar GoogleSignInException bila gagal/dibatalkan,
      //    sehingga accessToken dijamin non-null bila sampai sini.
      final authClient = account.authorizationClient;
      var authorization = await authClient.authorizationForScopes(_scopes);
      authorization ??= await authClient.authorizeScopes(_scopes);
      final String accessToken = authorization.accessToken;

      // 4. Kirim ke backend API
      final response = await DioClient.instance.dio.post(
        '/auth/google',
        data: {
          'access_token': accessToken,
          'id_token'    : idToken,
        },
      );

      if (response.data['success'] == true) {
        final data       = response.data['data'];
        final token      = data['token'] as String;
        final userData   = data['user'] as Map<String, dynamic>;

        return GoogleAuthResult.success(
          token: token,
          user: UserModel.fromJson(userData),
          isNewUser: userData['is_new_user'] == true,
        );
      } else {
        return GoogleAuthResult.error(
          response.data['message'] ?? 'Login Google gagal',
        );
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleAuthResult.cancelled();
      }
      return GoogleAuthResult.error('Login Google gagal: ${e.description ?? e.code.name}');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Koneksi ke server gagal';
      return GoogleAuthResult.error(message);
    } catch (e) {
      return GoogleAuthResult.error('Error: ${e.toString()}');
    }
  }

  /// Sign out dari Google
  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}

/// Result dari Google Sign-In flow
class GoogleAuthResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final String? token;
  final UserModel? user;
  final bool isNewUser;

  const GoogleAuthResult._({
    required this.success,
    required this.cancelled,
    this.error,
    this.token,
    this.user,
    this.isNewUser = false,
  });

  factory GoogleAuthResult.success({
    required String token,
    required UserModel user,
    bool isNewUser = false,
  }) =>
      GoogleAuthResult._(
        success: true,
        cancelled: false,
        token: token,
        user: user,
        isNewUser: isNewUser,
      );

  factory GoogleAuthResult.cancelled() =>
      const GoogleAuthResult._(success: false, cancelled: true);

  factory GoogleAuthResult.error(String message) =>
      GoogleAuthResult._(success: false, cancelled: false, error: message);
}
