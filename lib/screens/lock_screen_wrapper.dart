import 'dart:async';
import 'dart:math';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../services/security_service.dart';

/// Painter khusus untuk menggambar logo Dual-Arc SakuKos
class DualArcLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  const DualArcLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final paint1 = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    // Busur Atas-Kanan
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 4,
      pi * 0.72,
      false,
      paint1,
    );

    // Busur Bawah-Kiri
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3 * pi / 4,
      pi * 0.72,
      false,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wrapper layar pengunci aplikasi SakuKos (Hybrid PIN 6 Digit + Sidik Jari).
/// Menjaga akses aplikasi saat dibuka pertama kali atau saat kembali dari background.
class LockScreenWrapper extends StatefulWidget {
  final Widget child;

  const LockScreenWrapper({
    super.key,
    required this.child,
  });

  @override
  State<LockScreenWrapper> createState() => _LockScreenWrapperState();
}

class _LockScreenWrapperState extends State<LockScreenWrapper>
    with WidgetsBindingObserver {
  final SecurityService _securityService = SecurityService();
  bool _isLocked = false;
  bool _isAuthenticating = false;
  String _enteredPin = '';
  bool _hasError = false;
  String? _errorMessage;
  DateTime? _lastPausedTime;
  Timer? _authGuardTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Bypass darurat: Jangan kunci aplikasi jika PIN belum diset oleh pengguna
    if (_securityService.isSecurityActive()) {
      _isLocked = true;
      if (_securityService.isBiometricEnabled()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isLocked && !_isAuthenticating) {
            _triggerBiometricAuth();
          }
        });
      }
    } else {
      _isLocked = false;
    }
  }

  @override
  void dispose() {
    _authGuardTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Abaikan pencatatan waktu jika jeda disebabkan oleh dialog autentikasi biometrik
      if (_isAuthenticating) return;
      _lastPausedTime = clock.now();
    } else if (state == AppLifecycleState.resumed) {
      // 1. Abaikan jika sedang dalam proses autentikasi biometrik
      if (_isAuthenticating) return;

      final pausedTime = _lastPausedTime;
      _lastPausedTime = null;

      // 2. Cooldown / Grace Period: Hanya kunci jika berada di background >= 2 detik
      // Mencegah relock instan akibat transisi dialog sistem/biometrik Android
      final isBackgroundLongEnough = pausedTime != null &&
          clock.now().difference(pausedTime).inMilliseconds >= 2000;

      if (isBackgroundLongEnough &&
          _securityService.isSecurityActive() &&
          !_isLocked) {
        setState(() {
          _isLocked = true;
          _enteredPin = '';
          _hasError = false;
          _errorMessage = null;
        });
        if (_securityService.isBiometricEnabled() && !_isAuthenticating) {
          _triggerBiometricAuth();
        }
      }
    }
  }

  Future<void> _triggerBiometricAuth() async {
    // Pastikan single-trigger: Jangan panggil jika sedang autentikasi atau sudah tidak terkunci
    if (_isAuthenticating || !_isLocked) return;
    _isAuthenticating = true;

    try {
      final success = await _securityService.authenticateBiometrics(
        reason: 'Pindai sidik jari untuk membuka SakuKos',
      );
      if (success && mounted) {
        // Status buka kunci yang tegas & reset timestamp
        setState(() {
          _isLocked = false;
          _lastPausedTime = null;
          _enteredPin = '';
          _hasError = false;
          _errorMessage = null;
        });
      }
    } finally {
      // Jeda reset flag (600ms): Memberi waktu bagi OS Android untuk
      // menyelesaikan penutupan dialog biometrik tanpa memicu race condition pada resumed
      _authGuardTimer?.cancel();
      _authGuardTimer = Timer(const Duration(milliseconds: 600), () {
        _isAuthenticating = false;
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 6) {
      _verifyEnteredPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyEnteredPin() {
    final isValid = _securityService.verifyPin(_enteredPin);
    if (isValid) {
      setState(() {
        _isLocked = false;
        _lastPausedTime = null;
        _enteredPin = '';
        _hasError = false;
        _errorMessage = null;
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _hasError = true;
        _errorMessage = 'PIN salah, silakan coba lagi';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _securityService.listenable,
      builder: (context, _) {
        final isSecurityActive = _securityService.isSecurityActive();
        if (!isSecurityActive) {
          _isLocked = false;
          return widget.child;
        }

        if (!_isLocked) {
          return widget.child;
        }

        return _buildLockScreen(context);
      },
    );
  }

  Widget _buildLockScreen(BuildContext context) {
    final colors = SakuKosPalette.of(context);
    final isBiometricEnabled = _securityService.isBiometricEnabled();

    return Scaffold(
      key: const Key('lock_screen_view'),
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo Dual-Arc SakuKos ───────────────────────────
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(76, 76),
                        painter: DualArcLogoPainter(
                          primaryColor: colors.emerald,
                          secondaryColor: colors.rose,
                        ),
                      ),
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: colors.emerald,
                        size: 30,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Judul & Instruksi ───────────────────────────────
                Text(
                  'SakuKos Terkunci',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan 6 Digit PIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // ── 6 Indikator Dot Bulat ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      key: Key('pin_dot_$index'),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError
                            ? colors.rose
                            : isFilled
                                ? colors.emerald
                                : Colors.transparent,
                        border: Border.all(
                          color: _hasError
                              ? colors.rose
                              : isFilled
                                  ? colors.emerald
                                  : colors.border,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // ── Pesan Error (Placeholder Tinggi Tetap) ───────────
                SizedBox(
                  height: 20,
                  child: _errorMessage != null
                      ? Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.rose,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 20),

                // ── Custom Numpad ───────────────────────────────────
                _buildNumpad(context, colors, isBiometricEnabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(
    BuildContext context,
    SakuKosPalette colors,
    bool isBiometricEnabled,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          // Baris 1: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton('1', colors),
              _buildDigitButton('2', colors),
              _buildDigitButton('3', colors),
            ],
          ),
          const SizedBox(height: 16),

          // Baris 2: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton('4', colors),
              _buildDigitButton('5', colors),
              _buildDigitButton('6', colors),
            ],
          ),
          const SizedBox(height: 16),

          // Baris 3: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton('7', colors),
              _buildDigitButton('8', colors),
              _buildDigitButton('9', colors),
            ],
          ),
          const SizedBox(height: 16),

          // Baris 4: Sidik Jari (Kiri) / Kosong, 0 (Tengah), Backspace (Kanan)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (isBiometricEnabled)
                _buildActionButton(
                  key: const Key('unlock_biometric_button'),
                  icon: Icons.fingerprint_rounded,
                  iconColor: colors.emerald,
                  backgroundColor: colors.emerald.withAlpha(25),
                  onTap: _triggerBiometricAuth,
                )
              else
                const SizedBox(width: 68, height: 68),
              _buildDigitButton('0', colors),
              _buildActionButton(
                key: const Key('numpad_button_backspace'),
                icon: Icons.backspace_outlined,
                iconColor: colors.textSecondary,
                backgroundColor: colors.card,
                onTap: _onBackspacePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitButton(String digit, SakuKosPalette colors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('numpad_button_$digit'),
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(34),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.card,
            border: Border.all(color: colors.border.withAlpha(120)),
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(34),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(color: iconColor.withAlpha(60)),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 26,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
