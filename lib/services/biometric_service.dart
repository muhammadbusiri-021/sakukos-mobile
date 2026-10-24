import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'security_service.dart';

/// Service adapter untuk autentikasi biometrik SakuKos.
/// Mengarahkan pemanggilan ke [SecurityService] sebagai pusat manajemen keamanan.
class BiometricService {
  BiometricService._internal();

  static final BiometricService _instance = BiometricService._internal();

  /// Mengakses instance singleton [BiometricService].
  factory BiometricService({LocalAuthentication? localAuth}) {
    if (localAuth != null) {
      SecurityService(localAuth: localAuth);
    }
    return _instance;
  }

  final SecurityService _security = SecurityService();

  static const String boxName = SecurityService.boxName;
  static const String keyBiometricEnabled = SecurityService.keyBiometricEnabled;

  LocalAuthentication get auth => _security.auth;

  @visibleForTesting
  set auth(LocalAuthentication customAuth) => _security.auth = customAuth;

  Box get box => _security.box;

  Future<void> init() => _security.init();

  Future<void> close() => _security.close();

  bool isBiometricEnabled() => _security.isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled) =>
      _security.setBiometricEnabled(enabled);

  Future<bool> canCheckBiometrics() => _security.canCheckBiometrics();

  Future<bool> authenticate({
    String reason = 'Pindai sidik jari untuk membuka SakuKos',
    bool ignoreStatus = false,
  }) =>
      _security.authenticateBiometrics(
        reason: reason,
        ignoreStatus: ignoreStatus,
      );

  Listenable get listenable => _security.listenable;
}
