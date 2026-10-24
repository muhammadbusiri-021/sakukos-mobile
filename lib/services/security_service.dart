import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

/// Service singleton untuk mengelola sistem keamanan hybrid SakuKos:
/// PIN 6 digit (hashing SHA-256) dan verifikasi biometrik (sidik jari).
class SecurityService {
  SecurityService._internal();

  static final SecurityService _instance = SecurityService._internal();

  /// Mengakses instance singleton [SecurityService].
  factory SecurityService({LocalAuthentication? localAuth}) {
    if (localAuth != null) {
      _instance.auth = localAuth;
    }
    return _instance;
  }

  static const String boxName = 'settings_box';
  static const String keyPinEnabled = 'pin_enabled';
  static const String keyPinHash = 'pin_hash';
  static const String keyBiometricEnabled = 'biometric_enabled';

  LocalAuthentication auth = LocalAuthentication();
  Box? _box;
  bool _isAuthenticating = false;

  bool get isAuthenticating => _isAuthenticating;

  /// Getter untuk box Hive pengaturan aktif.
  Box get box {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
      return _box!;
    }
    throw StateError(
      'SecurityService belum diinisialisasi. Panggil SecurityService().init() terlebih dahulu.',
    );
  }

  /// Membuka box pengaturan jika belum terbuka.
  Future<void> init() async {
    _listenable = null;
    if (_box == null || !_box!.isOpen) {
      if (Hive.isBoxOpen(boxName)) {
        _box = Hive.box(boxName);
      } else {
        _box = await Hive.openBox(boxName);
      }
    }
    // Bypass darurat: Jika belum ada PIN yang valid, pastikan status keamanan tidak mengunci
    if (!isPinEnabled() && isBiometricEnabled()) {
      await disableSecurity();
    }
  }

  /// Menutup service dan melepaskan listener.
  Future<void> close() async {
    _listenable = null;
    _box = null;
  }

  /// Menghasilkan hash SHA-256 dari string PIN. PIN tidak pernah disimpan plaintext.
  String hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  /// Mengecek apakah fitur kunci PIN 6 digit diaktifkan dan memiliki hash tersimpan.
  bool isPinEnabled() {
    if (_box == null || !_box!.isOpen) {
      if (Hive.isBoxOpen(boxName)) {
        _box = Hive.box(boxName);
      } else {
        return false;
      }
    }
    final enabled = _box!.get(keyPinEnabled, defaultValue: false);
    final hash = _box!.get(keyPinHash);
    return enabled == true && hash is String && hash.isNotEmpty;
  }

  /// Mengambil hash PIN tersimpan (atau null jika belum diset).
  String? getPinHash() {
    if (_box == null || !_box!.isOpen) {
      if (Hive.isBoxOpen(boxName)) {
        _box = Hive.box(boxName);
      } else {
        return null;
      }
    }
    final hash = _box!.get(keyPinHash);
    return hash is String ? hash : null;
  }

  /// Mengecek apakah fitur buka cepat sidik jari diaktifkan.
  bool isBiometricEnabled() {
    if (_box == null || !_box!.isOpen) {
      if (Hive.isBoxOpen(boxName)) {
        _box = Hive.box(boxName);
      } else {
        return false;
      }
    }
    final enabled = _box!.get(keyBiometricEnabled, defaultValue: false);
    return enabled == true;
  }

  /// Mengecek apakah pengamanan aplikasi sedang aktif.
  /// Pengamanan hanya aktif jika pengguna telah mengatur PIN 6 digit yang valid.
  bool isSecurityActive() {
    return isPinEnabled();
  }

  /// Bypass darurat / pemulihan: Mereset seluruh pengamanan jika belum ada PIN yang dibuat,
  /// sehingga pengguna tidak terkunci di lock screen.
  Future<void> resetSecurityIfNoPin() async {
    if (!isPinEnabled()) {
      await disableSecurity();
    }
  }

  /// Menyimpan hash PIN 6 digit dan mengaktifkan status PIN.
  Future<void> savePin(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.length != 6 || int.tryParse(cleanPin) == null) {
      throw ArgumentError('PIN harus terdiri dari 6 digit angka');
    }
    final hashed = hashPin(cleanPin);
    await box.put(keyPinHash, hashed);
    await box.put(keyPinEnabled, true);
  }

  /// Memverifikasi PIN masukan pengguna dengan mencocokkan SHA-256 hash.
  bool verifyPin(String inputPin) {
    final savedHash = getPinHash();
    if (savedHash == null || savedHash.isEmpty) return false;
    final inputHash = hashPin(inputPin);
    return inputHash == savedHash;
  }

  /// Menyimpan status aktif/tidak kunci sidik jari.
  Future<void> setBiometricEnabled(bool enabled) async {
    await box.put(keyBiometricEnabled, enabled);
  }

  /// Menonaktifkan seluruh sistem pengamanan (PIN dan Sidik Jari).
  Future<void> disableSecurity() async {
    await box.put(keyPinEnabled, false);
    await box.put(keyBiometricEnabled, false);
  }

  /// Memeriksa apakah perangkat memiliki dukungan sensor biometrik.
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Menjalankan pemindaian sidik jari dengan pesan localizedReason.
  /// Diproteksi dengan [_isAuthenticating] agar tidak terjadi loop pemanggilan ganda.
  Future<bool> authenticateBiometrics({
    String reason = 'Pindai sidik jari untuk membuka SakuKos',
    bool ignoreStatus = false,
  }) async {
    if (!ignoreStatus && !isBiometricEnabled()) {
      return true;
    }

    if (_isAuthenticating) return false;
    _isAuthenticating = true;

    try {
      final authenticated = await auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return authenticated;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  ValueListenable<Box>? _listenable;

  /// Notifier agar UI dapat merespon perubahan status keamanan secara reaktif.
  Listenable get listenable {
    if (_listenable != null && _box != null && _box!.isOpen) {
      return _listenable!;
    }
    if (_box != null && _box!.isOpen) {
      _listenable = _box!.listenable(keys: [
        keyPinEnabled,
        keyPinHash,
        keyBiometricEnabled,
      ]);
      return _listenable!;
    }
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
      _listenable = _box!.listenable(keys: [
        keyPinEnabled,
        keyPinHash,
        keyBiometricEnabled,
      ]);
      return _listenable!;
    }
    return ValueNotifier<bool>(false);
  }
}
