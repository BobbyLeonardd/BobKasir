import 'package:shared_preferences/shared_preferences.dart';

/// Centralized local key-value storage wrapper
class AppStorage {
  AppStorage._();
  static AppStorage? _instance;
  static AppStorage get instance => _instance ??= AppStorage._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'AppStorage.init() must be called before use');
    return _prefs!;
  }

  // ──────────────── Auth ────────────────
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyUserName = 'auth_user_name';
  static const _keyUserEmail = 'auth_user_email';
  static const _keyUserRole = 'auth_user_role';
  static const _keyUserAvatar = 'auth_user_avatar';
  static const _keyBusinessId = 'auth_business_id';
  static const _keyBusinessName = 'auth_business_name';
  static const _keyDeviceId = 'device_id';
  static const _keyFirstLogin = 'first_login_done';
  static const _keyTrialPopupShown = 'trial_popup_shown';

  String? get token => _p.getString(_keyToken);
  Future<void> saveToken(String token) => _p.setString(_keyToken, token);
  Future<void> clearToken() => _p.remove(_keyToken);

  String? get userId => _p.getString(_keyUserId);
  String? get userName => _p.getString(_keyUserName);
  String? get userEmail => _p.getString(_keyUserEmail);
  String? get userRole => _p.getString(_keyUserRole);
  String? get userAvatar => _p.getString(_keyUserAvatar);
  String? get businessId => _p.getString(_keyBusinessId);
  String? get businessName => _p.getString(_keyBusinessName);
  String? get deviceId => _p.getString(_keyDeviceId);

  bool get isFirstLoginDone => _p.getBool(_keyFirstLogin) ?? false;
  bool get isTrialPopupShown => _p.getBool(_keyTrialPopupShown) ?? false;

  Future<void> saveUserSession({
    required String token,
    required String userId,
    required String name,
    required String email,
    required String role,
    String? avatar,
    required String businessId,
    required String businessName,
  }) async {
    await Future.wait([
      _p.setString(_keyToken, token),
      _p.setString(_keyUserId, userId),
      _p.setString(_keyUserName, name),
      _p.setString(_keyUserEmail, email),
      _p.setString(_keyUserRole, role),
      if (avatar != null) _p.setString(_keyUserAvatar, avatar),
      _p.setString(_keyBusinessId, businessId),
      _p.setString(_keyBusinessName, businessName),
    ]);
  }

  Future<void> markFirstLoginDone() => _p.setBool(_keyFirstLogin, true);
  Future<void> markTrialPopupShown() => _p.setBool(_keyTrialPopupShown, true);

  Future<void> saveDeviceId(String id) => _p.setString(_keyDeviceId, id);

  Future<void> clearSession() async {
    await Future.wait([
      _p.remove(_keyToken),
      _p.remove(_keyUserId),
      _p.remove(_keyUserName),
      _p.remove(_keyUserEmail),
      _p.remove(_keyUserRole),
      _p.remove(_keyUserAvatar),
      _p.remove(_keyBusinessId),
      _p.remove(_keyBusinessName),
    ]);
  }

  // ──────────────── Theme ────────────────
  static const _keyTheme = 'app_theme_mode';
  String? get savedTheme => _p.getString(_keyTheme);
  Future<void> saveTheme(String mode) => _p.setString(_keyTheme, mode);

  // ──────────────── Printer ────────────────
  static const _keyPrinterName = 'printer_name';
  static const _keyPrinterAddress = 'printer_address';
  static const _keyPaperSize = 'printer_paper_size';

  String? get printerName => _p.getString(_keyPrinterName);
  String? get printerAddress => _p.getString(_keyPrinterAddress);
  String get paperSize => _p.getString(_keyPaperSize) ?? '80mm';

  Future<void> savePrinter(String name, String address) async {
    await _p.setString(_keyPrinterName, name);
    await _p.setString(_keyPrinterAddress, address);
  }

  Future<void> savePaperSize(String size) => _p.setString(_keyPaperSize, size);

  // ──────────────── Cash Drawer ────────────────
  static const _keyCashDrawerMode = 'cash_drawer_mode';
  String get cashDrawerMode =>
      _p.getString(_keyCashDrawerMode) ?? 'off';
  Future<void> saveCashDrawerMode(String mode) =>
      _p.setString(_keyCashDrawerMode, mode);
}
