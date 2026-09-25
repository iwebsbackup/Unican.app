import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'permission_service.dart';

class LocationService {
  final PermissionService _permissions = PermissionService();

  Future<Position?> getCurrentPosition() async {
    if (!Platform.isAndroid) return null;
    if (!await _permissions.requestLocation()) return null;
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    return Geolocator.getCurrentPosition();
  }

  Future<bool> isServiceEnabled() async {
    if (!Platform.isAndroid) return false;
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> openLocationSettings() async {
    if (!Platform.isAndroid) return false;
    return Geolocator.openLocationSettings();
  }
}
