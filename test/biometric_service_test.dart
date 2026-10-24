import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sakukos/services/biometric_service.dart';

class FakeLocalAuthentication extends Fake implements LocalAuthentication {
  bool authenticateResult = true;
  bool canCheck = true;
  String? lastReason;

  @override
  Future<bool> get canCheckBiometrics => Future.value(canCheck);

  @override
  Future<bool> isDeviceSupported() => Future.value(canCheck);

  @override
  Future<bool> authenticate({
    required String localizedReason,
    dynamic authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    lastReason = localizedReason;
    return authenticateResult;
  }
}

void main() {
  late Directory tempDir;
  late BiometricService biometricService;
  late FakeLocalAuthentication fakeAuth;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sakukos_biometric_test_');
    Hive.init(tempDir.path);
    biometricService = BiometricService();
    fakeAuth = FakeLocalAuthentication();
    biometricService.auth = fakeAuth;
    await biometricService.init();
    await biometricService.box.clear();
  });

  tearDown(() async {
    await biometricService.box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BiometricService Tests', () {
    test('isBiometricEnabled returns false by default', () {
      expect(biometricService.isBiometricEnabled(), false);
    });

    test('setBiometricEnabled updates Hive settings_box accurately', () async {
      await biometricService.setBiometricEnabled(true);
      expect(biometricService.isBiometricEnabled(), true);

      await biometricService.setBiometricEnabled(false);
      expect(biometricService.isBiometricEnabled(), false);
    });

    test('canCheckBiometrics checks hardware capability', () async {
      fakeAuth.canCheck = true;
      expect(await biometricService.canCheckBiometrics(), true);

      fakeAuth.canCheck = false;
      expect(await biometricService.canCheckBiometrics(), false);
    });

    test('authenticate returns true when biometric lock is disabled', () async {
      await biometricService.setBiometricEnabled(false);
      fakeAuth.authenticateResult = false; // auth shouldn't even be called
      final result = await biometricService.authenticate();
      expect(result, true);
      expect(fakeAuth.lastReason, isNull);
    });

    test('authenticate triggers local authentication when biometric is enabled',
        () async {
      await biometricService.setBiometricEnabled(true);
      fakeAuth.authenticateResult = true;

      final result = await biometricService.authenticate();
      expect(result, true);
      expect(
        fakeAuth.lastReason,
        'Pindai sidik jari untuk membuka SakuKos',
      );
    });

    test('authenticate handles failed biometric scan', () async {
      await biometricService.setBiometricEnabled(true);
      fakeAuth.authenticateResult = false;

      final result = await biometricService.authenticate();
      expect(result, false);
    });

    test('authenticate with ignoreStatus=true bypasses enabled check',
        () async {
      await biometricService.setBiometricEnabled(false);
      fakeAuth.authenticateResult = true;

      final result = await biometricService.authenticate(ignoreStatus: true);
      expect(result, true);
      expect(
        fakeAuth.lastReason,
        'Pindai sidik jari untuk membuka SakuKos',
      );
    });
  });
}
