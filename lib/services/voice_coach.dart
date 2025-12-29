import 'package:flutter_tts/flutter_tts.dart';

/// Simple voice coach that speaks cues with cooldown
class VoiceCoach {
  final FlutterTts _tts = FlutterTts();
  DateTime? _lastSpoke;
  static const _cooldown = Duration(seconds: 3);
  
  bool _initialized = false;
  
  Future<void> init() async {
    if (_initialized) return;
    
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1);
    
    _initialized = true;
  }
  
  /// Speak a message (respects cooldown)
  Future<void> speak(String message) async {
    if (!_initialized) await init();
    
    final now = DateTime.now();
    if (_lastSpoke != null && now.difference(_lastSpoke!) < _cooldown) {
      return; // Skip if too soon
    }
    
    _lastSpoke = now;
    await _tts.speak(message);
    print('🗣️ TTS: $message'); // Debug output
  }
  
  /// Speak immediately (ignores cooldown) - for rep counts
  Future<void> speakNow(String message) async {
    if (!_initialized) await init();
    await _tts.speak(message);
    print('🗣️ TTS: $message'); // Debug output
    _lastSpoke = DateTime.now();
  }
  
  /// Announce rep count
  Future<void> announceRep(int count) async {
    await speakNow('$count');
  }
  
  /// Announce exercise start
  Future<void> announceExercise(String name, int sets, int reps) async {
    await speakNow('$name. $sets sets of $reps reps.');
  }
  
  /// Announce set complete
  Future<void> announceSetComplete(int setNumber, int totalSets) async {
    if (setNumber >= totalSets) {
      await speakNow('Exercise complete!');
    } else {
      await speakNow('Set $setNumber complete. Rest.');
    }
  }
  
  /// Give form feedback
  Future<void> giveFeedback(String feedback) async {
    if (feedback.isNotEmpty) {
      await speak(feedback);
    }
  }
  
  Future<void> dispose() async {
    await _tts.stop();
  }
}

