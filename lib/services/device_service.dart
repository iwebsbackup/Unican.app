import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return info.id;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return info.identifierForVendor ?? 'unknown-ios-device';
    }
    return 'unknown-device';
  }
}