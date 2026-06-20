import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:safe_device/safe_device.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getFullDeviceAudit() async {
    bool isRooted = await SafeDevice.isJailBroken;
    bool isRealDevice = await SafeDevice.isRealDevice;
    bool isDevMode = await SafeDevice.isDevelopmentModeEnable;
    
    Map<String, dynamic> audit = {
      'isRooted': isRooted,
      'isRealDevice': isRealDevice,
      'isDevMode': isDevMode,
      'model': 'Unknown',
      'osVersion': 'Unknown',
      'securityPatch': 'Unknown',
    };

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      audit['model'] = androidInfo.model;
      audit['osVersion'] = 'Android ${androidInfo.version.release}';
      audit['securityPatch'] = androidInfo.version.securityPatch ?? 'Unknown';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      audit['model'] = iosInfo.utsname.machine;
      audit['osVersion'] = 'iOS ${iosInfo.systemVersion}';
    }

    return audit;
  }
}
