import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../storage/app_storage.dart';

abstract class DeviceHelper {
  static Future<String> getOrCreateDeviceId() async {
    final stored = AppStorage.instance.deviceId;
    if (stored != null && stored.isNotEmpty) return stored;

    // Generate new device ID
    final info = DeviceInfoPlugin();
    String deviceId;

    try {
      final android = await info.androidInfo;
      deviceId = android.id; // Android hardware ID
    } catch (_) {
      deviceId = const Uuid().v4();
    }

    await AppStorage.instance.saveDeviceId(deviceId);
    return deviceId;
  }

  static Future<String> getDeviceName() async {
    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      return '${android.brand} ${android.model}';
    } catch (_) {
      return 'Unknown Device';
    }
  }
}
