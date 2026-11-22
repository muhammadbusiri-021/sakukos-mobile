import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Service terisolasi untuk mengelola pengenalan suara (Voice-to-Text).
/// Membungkus [SpeechToText] untuk mendukung input transaksi berbasis ucapan.
class VoiceRecognitionService {
  VoiceRecognitionService({SpeechToText? speechToText})
      : _speech = speechToText ?? SpeechToText();

  static final VoiceRecognitionService _defaultInstance =
      VoiceRecognitionService();

  /// Mengakses instance default dari [VoiceRecognitionService].
  factory VoiceRecognitionService.instance() => _defaultInstance;

  final SpeechToText _speech;
  bool _isInitialized = false;
  Function(bool isListening)? _onListeningChangedCallback;

  /// Mengembalikan apakah recognizer sudah diinisialisasi.
  bool get isInitialized => _isInitialized;

  /// Mengembalikan status apakah mikrofon sedang aktif mendengarkan.
  bool get isListening => _speech.isListening;

  /// Inisialisasi engine pengenalan suara dan memeriksa ketersediaan izin audio.
  Future<bool> initialize() async {
    if (_isInitialized && _speech.isAvailable) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
      return _isInitialized;
    } catch (_) {
      _isInitialized = false;
      return false;
    }
  }

  /// Mulai mendengarkan suara pengguna dengan preferensi locale Indonesia (`id_ID`).
  /// Teks hasil ucapan dikirimkan secara streaming melalui [onResult].
  Future<void> startListening({
    required Function(String text) onResult,
    Function(bool isListening)? onListeningChanged,
  }) async {
    _onListeningChangedCallback = onListeningChanged;

    if (!_isInitialized) {
      final available = await initialize();
      if (!available) {
        onListeningChanged?.call(false);
        return;
      }
    }

    try {
      // Prioritaskan locale Indonesia jika perangkat mendukung
      String? targetLocaleId = 'id_ID';
      final locales = await _speech.locales();
      final hasIndonesian = locales.any((loc) =>
          loc.localeId == 'id_ID' ||
          loc.localeId.toLowerCase().startsWith('id'));
      if (!hasIndonesian && locales.isNotEmpty) {
        targetLocaleId = null; // Fallback ke default sistem
      }

      onListeningChanged?.call(true);

      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          localeId: targetLocaleId,
        ),
      );
    } catch (_) {
      onListeningChanged?.call(false);
    }
  }

  /// Menghentikan perekaman suara secara bersih.
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {
      // Abaikan error saat penghentian paksa
    } finally {
      final cb = _onListeningChangedCallback;
      _onListeningChangedCallback = null;
      cb?.call(false);
    }
  }

  /// Membatalkan sesi pengenalan suara tanpa memproses hasil akhir.
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // Abaikan error saat pembatalan
    } finally {
      final cb = _onListeningChangedCallback;
      _onListeningChangedCallback = null;
      cb?.call(false);
    }
  }

  void _handleStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      _onListeningChangedCallback?.call(false);
    } else if (status == 'listening') {
      _onListeningChangedCallback?.call(true);
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _onListeningChangedCallback?.call(false);
  }
}
