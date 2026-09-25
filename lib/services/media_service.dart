import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'permission_service.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();
  final PermissionService _permissions = PermissionService();

  Future<XFile?> capturePhoto() async {
    if (!Platform.isAndroid) return null;
    if (!await _permissions.requestCamera()) return null;
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<XFile?> pickPhoto() async {
    if (!Platform.isAndroid) return null;
    if (!await _permissions.requestPhotos()) return null;
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  }

  Future<List<XFile>> pickPhotos() async {
    if (!Platform.isAndroid) return <XFile>[];
    if (!await _permissions.requestPhotos()) return <XFile>[];
    return _picker.pickMultiImage(imageQuality: 85);
  }
}
