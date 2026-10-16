import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/verification_case.dart';
import 'database_service.dart';
import 'imgbb_service.dart';
import 'local_storage_service.dart';

/// Offline-first sync engine.
///
/// Finished verifications are written to Hive first (see [LocalStorageService]).
/// [enqueue] then tries to push them to Firebase. If the device is offline the
/// record stays queued and is retried automatically as soon as connectivity
/// comes back.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final DatabaseService _db = DatabaseService();
  final LocalStorageService _local = LocalStorageService.instance;
  final ImgbbService _imgbb = ImgbbService.instance;

  /// Photo upload retries before we stop and keep the verification submitted
  /// with whatever URLs we already have.
  static const int _maxPhotoAttempts = 8;

  /// Number of verifications whose metadata has not reached Firebase yet.
  ///
  /// Photo uploads that are still retrying in the background are deliberately
  /// not counted here: the verification itself is already submitted, so the
  /// user should not be told it is "pending sync".
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// Whether the device currently has a network connection.
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _retryTimer;
  bool _initialized = false;
  bool _syncing = false;
  bool _syncQueued = false;

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _local.init();
    _refreshPendingCount();

    await _refreshConnectivity();

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      online.value = _hasConnection(results);
      if (online.value) syncNow();
    });

    if (online.value) syncNow();
  }

  /// Re-reads the platform connectivity state. Used before skipping a sync so a
  /// stale "offline" flag never parks an online submit.
  Future<void> _refreshConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      online.value = _hasConnection(results);
    } catch (_) {}
  }

  /// Save a finished verification to the local queue and attempt an immediate
  /// upload. The local copy is written before any network call, so nothing is
  /// lost when the device is offline.
  Future<void> enqueue(VerificationCase value, {required String uid}) async {
    await _local.init();

    final key = value.localKey;
    final existing = _local.getPending(key);

    await _local.putPending(key, <String, dynamic>{
      'key': key,
      'id': value.id,
      'uid': uid,
      'case': value.toMap(),
      'uploadedCount': existing?['uploadedCount'] ?? 0,
      'attempts': existing?['attempts'] ?? 0,
      // A fresh user save must always (re)push its metadata to Firebase; the
      // flag is only used to skip redundant pushes during background photo
      // retries.
      'metadataSynced': false,
      'lastError': '',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _refreshPendingCount();

    await syncNow();
  }

  /// Flush every queued verification to Firebase. Safe to call repeatedly;
  /// concurrent calls are coalesced, and anything enqueued while a sync is
  /// already running is picked up by the same pass.
  Future<void> syncNow() async {
    if (_syncing) {
      _syncQueued = true;
      return;
    }
    if (!_local.isReady) await _local.init();
    if (_local.allPending().isEmpty) {
      _refreshPendingCount();
      return;
    }

    if (!online.value) {
      await _refreshConnectivity();
    }
    if (!online.value) {
      _refreshPendingCount();
      _scheduleRetry();
      return;
    }

    _syncing = true;
    try {
      do {
        _syncQueued = false;
        for (final record in _local.allPending()) {
          await _syncRecord(record);
        }
      } while (_syncQueued);
    } finally {
      _syncing = false;
      _refreshPendingCount();
      _scheduleRetry();
    }
  }

  /// A record can fail while the device is technically online (flaky network,
  /// imgbb hiccup). Retry on a timer until the queue is empty instead of
  /// waiting for the next connectivity event.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (_local.allPending().isEmpty) return;
    _retryTimer = Timer(const Duration(seconds: 30), () async {
      await _refreshConnectivity();
      await syncNow();
    });
  }

  Future<void> _syncRecord(Map<String, dynamic> record) async {
    final key = (record['key'] ?? '').toString();
    final uid = (record['uid'] ?? '').toString();
    final rawCase = record['case'];

    if (key.isEmpty || uid.isEmpty || rawCase is! Map) {
      if (key.isNotEmpty) await _local.deletePending(key);
      return;
    }

    final caseMap = Map<String, dynamic>.from(rawCase);
    final value = VerificationCase.fromMap(
      (record['id'] ?? caseMap['id'] ?? '').toString(),
      caseMap,
    );

    // 1) Push the verification metadata to Firebase Realtime Database FIRST.
    //    This is what makes the record "submitted", so it must never wait on a
    //    photo upload. When this succeeds the verification is safely stored and
    //    the "pending sync" indicator clears even if photos still retry.
    if (record['metadataSynced'] != true) {
      try {
        await _db.saveCompletedCase(uid, value);
        if (value.firebaseKey.isNotEmpty) {
          await _db.updateAddressStatus(value.firebaseKey, 'Completed');
        }
        record['metadataSynced'] = true;
        record['attempts'] = 0;
        record['lastError'] = '';
        record['updatedAt'] = DateTime.now().toIso8601String();
        await _local.putPending(key, record);
        _refreshPendingCount();
      } catch (e) {
        record['attempts'] = ((record['attempts'] as num?)?.toInt() ?? 0) + 1;
        record['lastError'] = e.toString();
        record['updatedAt'] = DateTime.now().toIso8601String();
        await _local.putPending(key, record);
        return; // retry when connectivity is available again
      }
    }

    // 2) Upload any photos that are not hosted yet. Best-effort: a failed
    //    upload is retried in the background and never un-syncs the record.
    var photosPending = false;
    var uploadedNew = false;
    var abandonPhotos = false;
    if (_imgbb.isConfigured && value.photoPaths.isNotEmpty) {
      var already = (record['uploadedCount'] as num?)?.toInt() ?? 0;
      // A previously synced edit already carries hosted URLs.
      if (value.photoUrls.length > already) already = value.photoUrls.length;

      if (already < value.photoPaths.length) {
        final photoAttempts = (record['photoAttempts'] as num?)?.toInt() ?? 0;
        if (photoAttempts >= _maxPhotoAttempts) {
          // Give up on photos that keep failing (e.g. a rejected upload key)
          // so the background retry does not loop forever. The verification
          // metadata is already safely in Firebase.
          abandonPhotos = true;
        } else {
          final urls = List<String>.from(value.photoUrls);
          var uploaded = already;

          for (var i = already; i < value.photoPaths.length; i++) {
            final path = value.photoPaths[i];
            // A cached capture may have been cleared by the OS while offline.
            // Skip the missing file and keep the metadata moving instead of
            // blocking the whole record forever.
            if (!await File(path).exists()) {
              uploaded = i + 1;
              continue;
            }
            final url = await _imgbb.upload(path);
            if (url == null) {
              photosPending = true;
              break;
            }
            urls.add(url);
            uploaded = i + 1;
            uploadedNew = true;
          }

          value.photoUrls
            ..clear()
            ..addAll(urls);
          record['case'] = value.toMap();
          record['uploadedCount'] = uploaded;
          record['photoAttempts'] = photoAttempts + 1;
          record['updatedAt'] = DateTime.now().toIso8601String();

          // Refresh Firebase so the admin dashboard sees the hosted URLs.
          if (uploadedNew) {
            try {
              await _db.saveCompletedCase(uid, value);
            } catch (_) {
              photosPending = true;
            }
          }
        }
      }
    }

    // 3) Keep the record only while photos are still outstanding, so the
    //    "pending sync" indicator clears as soon as the case is submitted.
    final hasPhotos = _imgbb.isConfigured && value.photoPaths.isNotEmpty;
    final uploadedCount = (record['uploadedCount'] as num?)?.toInt() ?? 0;
    final effectiveUploaded =
        uploadedCount > value.photoUrls.length ? uploadedCount : value.photoUrls.length;
    final allUploaded = !hasPhotos || effectiveUploaded >= value.photoPaths.length;
    if ((!photosPending && allUploaded) || abandonPhotos) {
      await _local.deletePending(key);
    } else {
      record['case'] = value.toMap();
      await _local.putPending(key, record);
    }
  }

  /// True when a finished verification for [key] has not reached Firebase yet.
  bool isPending(String key) {
    final record = _local.getPending(key);
    return record != null && record['metadataSynced'] != true;
  }

  void _refreshPendingCount() {
    pendingCount.value = _local
        .allPending()
        .where((r) => r['metadataSynced'] != true)
        .length;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
