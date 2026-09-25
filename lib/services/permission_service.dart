import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  bool get _isAndroid => Platform.isAndroid;

  Future<bool> requestCamera() async {
    if (!_isAndroid) return true;
    return _granted(await Permission.camera.request());
  }

  Future<bool> requestPhotos() async {
    if (!_isAndroid) return true;
    if (_granted(await Permission.photos.request())) return true;
    return _granted(await Permission.storage.request());
  }

  Future<bool> requestLocation() async {
    if (!_isAndroid) return true;
    return _granted(await Permission.locationWhenInUse.request());
  }

  Future<bool> hasCameraPermission() async {
    if (!_isAndroid) return true;
    return _granted(await Permission.camera.status);
  }

  Future<bool> hasPhotoPermission() async {
    if (!_isAndroid) return true;
    if (_granted(await Permission.photos.status)) return true;
    return _granted(await Permission.storage.status);
  }

  Future<bool> hasLocationPermission() async {
    if (!_isAndroid) return true;
    return _granted(await Permission.locationWhenInUse.status);
  }

  Future<bool> openSettings() {
    if (!_isAndroid) return Future.value(false);
    return openAppSettings();
  }

  bool _granted(PermissionStatus status) =>
      status.isGranted || status.isLimited;
}
