import 'package:flutter_test/flutter_test.dart';
import 'package:sakukos/services/voice_recognition_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class FakeSpeechToText extends Fake implements SpeechToText {
  bool initResult = true;
  bool isAvailableVal = true;
  bool isListeningVal = false;
  List<LocaleName> mockLocales = [
    LocaleName('id_ID', 'Bahasa Indonesia'),
    LocaleName('en_US', 'English (United States)'),
  ];

  @override
  SpeechStatusListener? statusListener;
  @override
  SpeechErrorListener? errorListener;
  SpeechResultListener? resultListener;

  @override
  bool get isAvailable => isAvailableVal;

  @override
  bool get isListening => isListeningVal;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    statusListener = onStatus;
    errorListener = onError;
    return initResult;
  }

  @override
  Future<List<LocaleName>> locales() async {
    return mockLocales;
  }

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    dynamic onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    resultListener = onResult;
    isListeningVal = true;
    statusListener?.call('listening');
  }

  @override
  Future<void> stop() async {
    isListeningVal = false;
    statusListener?.call('notListening');
  }

  @override
  Future<void> cancel() async {
    isListeningVal = false;
    statusListener?.call('done');
  }
}

void main() {
  group('VoiceRecognitionService Tests', () {
    late FakeSpeechToText fakeSpeech;
    late VoiceRecognitionService service;

    setUp(() {
      fakeSpeech = FakeSpeechToText();
      service = VoiceRecognitionService(speechToText: fakeSpeech);
    });

    test('initialize returns true when SpeechToText initializes successfully',
        () async {
      final success = await service.initialize();
      expect(success, isTrue);
      expect(service.isInitialized, isTrue);
    });

    test('initialize returns false when SpeechToText initialization fails',
        () async {
      fakeSpeech.initResult = false;
      final success = await service.initialize();
      expect(success, isFalse);
      expect(service.isInitialized, isFalse);
    });

    test('startListening triggers onListeningChanged and streams onResult',
        () async {
      bool? listeningState;
      String? recognizedText;

      await service.startListening(
        onResult: (text) => recognizedText = text,
        onListeningChanged: (isListening) => listeningState = isListening,
      );

      expect(listeningState, isTrue);
      expect(service.isListening, isTrue);

      // Simulate recognition result
      final mockWords = <SpeechRecognitionWords>[
        const SpeechRecognitionWords('nasi padang dua puluh ribu', [], 0.95),
      ];
      final mockResult = SpeechRecognitionResult(
        mockWords,
        ResultType.finalResult.value,
      );
      fakeSpeech.resultListener?.call(mockResult);

      expect(recognizedText, 'nasi padang dua puluh ribu');
    });

    test('stopListening stops SpeechToText and updates listening state',
        () async {
      bool? listeningState;

      await service.startListening(
        onResult: (_) {},
        onListeningChanged: (isListening) => listeningState = isListening,
      );
      expect(listeningState, isTrue);

      await service.stopListening();
      expect(service.isListening, isFalse);
      expect(listeningState, isFalse);
    });

    test('cancelListening cancels speech session cleanly', () async {
      bool? listeningState;

      await service.startListening(
        onResult: (_) {},
        onListeningChanged: (isListening) => listeningState = isListening,
      );

      await service.cancelListening();
      expect(service.isListening, isFalse);
      expect(listeningState, isFalse);
    });

    test('handles speech error gracefully by notifying listening state',
        () async {
      bool? listeningState;

      await service.startListening(
        onResult: (_) {},
        onListeningChanged: (isListening) => listeningState = isListening,
      );
      expect(listeningState, isTrue);

      // Trigger error listener
      fakeSpeech.errorListener?.call(
        SpeechRecognitionError('error_no_match', true),
      );

      expect(listeningState, isFalse);
    });
  });
}
