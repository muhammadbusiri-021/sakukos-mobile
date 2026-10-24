import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sakukos/services/security_service.dart';

class FakeLocalAuth extends Fake implements LocalAuthentication {
  bool authResult = true;
  bool canCheck = true;
  int authCallCount = 0;

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
    authCallCount++;
    return authResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SecurityService securityService;
  late FakeLocalAuth fakeAuth;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sakukos_sec_test_');
    Hive.init(tempDir.path);

    fakeAuth = FakeLocalAuth();
    securityService = SecurityService(localAuth: fakeAuth);
    await securityService.init();
    await securityService.box.clear();
  });

  tearDown(() async {
    await securityService.box.clear();
    await securityService.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SecurityService Tests', () {
    test('Initial state: PIN and Biometrics are disabled', () {
      expect(securityService.isPinEnabled(), false);
      expect(securityService.isBiometricEnabled(), false);
      expect(securityService.isSecurityActive(), false);
      expect(securityService.getPinHash(), isNull);
    });

    test('savePin hashes PIN with SHA-256 and enables PIN security', () async {
      await securityService.savePin('123456');

      expect(securityService.isPinEnabled(), true);
      expect(securityService.isSecurityActive(), true);
      expect(securityService.getPinHash(), isNotNull);
      expect(securityService.getPinHash(), isNot('123456'));
      expect(securityService.getPinHash()!.length, 64); // SHA-256 length
    });

    test('savePin rejects invalid PIN lengths or non-numeric characters', () async {
      expect(() => securityService.savePin('123'), throwsArgumentError);
      expect(() => securityService.savePin('1234567'), throwsArgumentError);
      expect(() => securityService.savePin('abcdef'), throwsArgumentError);
    });

    test('verifyPin checks input against saved hash accurately', () async {
      await securityService.savePin('456789');

      expect(securityService.verifyPin('456789'), true);
      expect(securityService.verifyPin('123456'), false);
      expect(securityService.verifyPin('000000'), false);
    });

    test('setBiometricEnabled updates Hive settings_box accurately', () async {
      expect(securityService.isBiometricEnabled(), false);
      await securityService.setBiometricEnabled(true);
      expect(securityService.isBiometricEnabled(), true);
      await securityService.setBiometricEnabled(false);
      expect(securityService.isBiometricEnabled(), false);
    });

    test('disableSecurity disables both PIN and Biometrics', () async {
      await securityService.savePin('999999');
      await securityService.setBiometricEnabled(true);

      expect(securityService.isPinEnabled(), true);
      expect(securityService.isBiometricEnabled(), true);
      expect(securityService.isSecurityActive(), true);

      await securityService.disableSecurity();

      expect(securityService.isPinEnabled(), false);
      expect(securityService.isBiometricEnabled(), false);
      expect(securityService.isSecurityActive(), false);
    });

    test('authenticateBiometrics interacts with local authentication', () async {
      await securityService.setBiometricEnabled(true);
      fakeAuth.authResult = true;

      final result = await securityService.authenticateBiometrics();
      expect(result, true);
      expect(fakeAuth.authCallCount, 1);
    });

    test('authenticateBiometrics returns true immediately if biometric is disabled', () async {
      await securityService.setBiometricEnabled(false);
      final result = await securityService.authenticateBiometrics();
      expect(result, true);
      expect(fakeAuth.authCallCount, 0);
    });

    test('canCheckBiometrics checks hardware capability', () async {
      fakeAuth.canCheck = true;
      expect(await securityService.canCheckBiometrics(), true);
    });
  });
}
