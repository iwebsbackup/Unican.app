import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'device_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
  final DeviceService _deviceService = DeviceService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Signs in, then checks the device id against the one saved at
  /// registration. If they don't match, the user is signed back out
  /// and a FirebaseAuthException is thrown.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      final currentDeviceId = await _deviceService.getDeviceId();
      final userData = await _db.getUser(user.uid);
      final savedDeviceId = userData?['deviceId'] as String?;

      if (savedDeviceId != null && savedDeviceId != currentDeviceId) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'device-mismatch',
          message: 'This account is registered on a different device.',
        );
      }
    }
    return user;
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(name);
      final deviceId = await _deviceService.getDeviceId();
      await _db.createUserNode(
        uid: user.uid,
        name: name,
        email: email,
        deviceId: deviceId,
      );
    }
    return user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}