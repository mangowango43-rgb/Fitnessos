import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:collection';

enum SpeechPriority { critical, repCount, setStatus, formAlert, coaching }

enum MuscleGroup { chest, back, shoulders, legs, arms, core, fullBody, cardio }

class _SpeechItem {
  final String message;
  final SpeechPriority priority;
  final DateTime createdAt;
  final Duration? maxAge;

  _SpeechItem({required this.message, required this.priority, DateTime? createdAt, this.maxAge})
      : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => maxAge != null && DateTime.now().difference(createdAt) > (maxAge ?? Duration.zero);
}

class VoiceCoach {
  final FlutterTts _tts = FlutterTts();
  
  bool _initialized = false;
  bool _isSpeaking = false;
  bool _isEnabled = true;
  
  String? _currentExerciseId;
  MuscleGroup _currentMuscleGroup = MuscleGroup.fullBody;
  
  final Queue<_SpeechItem> _speechQueue = Queue();
  
  final Map<SpeechPriority, DateTime> _lastSpoke = {};
  static const Map<SpeechPriority, Duration> _cooldowns = {
    SpeechPriority.critical: Duration.zero,
    SpeechPriority.repCount: Duration(milliseconds: 500),
    SpeechPriority.setStatus: Duration(seconds: 2),
    SpeechPriority.formAlert: Duration(seconds: 3),
    SpeechPriority.coaching: Duration(seconds: 5),
  };
  
  // BLOCKED WORDS BY MUSCLE GROUP - NO SHOULDER TALK ON LEG DAY
  static const Map<MuscleGroup, List<String>> _blockedWords = {
    MuscleGroup.legs: ['shoulder', 'arm', 'elbow', 'wrist', 'chest', 'lat', 'tricep', 'bicep'],
    MuscleGroup.chest: ['knee', 'ankle', 'squat', 'lunge', 'hip thrust', 'glute', 'calf'],
    MuscleGroup.back: ['knee', 'ankle', 'squat', 'lunge', 'quad', 'calf'],
    MuscleGroup.shoulders: ['knee', 'ankle', 'squat', 'lunge', 'glute', 'calf'],
    MuscleGroup.arms: ['knee', 'ankle', 'squat', 'lunge', 'glute', 'hip', 'calf'],
    MuscleGroup.core: [],
    MuscleGroup.fullBody: [],
    MuscleGroup.cardio: [],
  };
  
  Future<void> init() async {
    if (_initialized) return;
    
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.52);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
    await _tts.setSharedInstance(true);
    
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
    
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _processQueue();
    });
    
    _initialized = true;
  }
  
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _tts.stop();
      _speechQueue.clear();
    }
  }
  
  // CONTEXT LOCK
  void lockToExercise(String exerciseId) {
    _currentExerciseId = exerciseId;
    _currentMuscleGroup = _getMuscleGroup(exerciseId);
  }
  
  void unlock() {
    _currentExerciseId = null;
    _currentMuscleGroup = MuscleGroup.fullBody;
  }
  
  MuscleGroup _getMuscleGroup(String exerciseId) {
    final id = exerciseId.toLowerCase();
    
    if (id.contains('squat') || id.contains('lunge') || id.contains('leg') ||
        id.contains('calf') || id.contains('deadlift') || id.contains('thrust') ||
        id.contains('glute') || id.contains('step') || id.contains('curl') && id.contains('leg')) {
      return MuscleGroup.legs;
    }
    if (id.contains('bench') || id.contains('push') || id.contains('fly') ||
        id.contains('chest') || id.contains('dip') && !id.contains('tricep')) {
      return MuscleGroup.chest;
    }
    if (id.contains('row') || id.contains('pull') || id.contains('lat') ||
        id.contains('back') || id.contains('shrug')) {
      return MuscleGroup.back;
    }
    if (id.contains('shoulder') || id.contains('raise') || id.contains('delt')) {
      return MuscleGroup.shoulders;
    }
    if (id.contains('curl') || id.contains('tricep') || id.contains('bicep') ||
        id.contains('extension') || id.contains('hammer') || id.contains('skull')) {
      return MuscleGroup.arms;
    }
    if (id.contains('plank') || id.contains('crunch') || id.contains('twist') ||
        id.contains('mountain') || id.contains('dead_bug')) {
      return MuscleGroup.core;
    }
    if (id.contains('jump') || id.contains('burpee') || id.contains('jack') ||
        id.contains('climber') || id.contains('high_knee')) {
      return MuscleGroup.cardio;
    }
    
    return MuscleGroup.fullBody;
  }
  
  bool _isRelevantMessage(String message) {
    final blockedWords = _blockedWords[_currentMuscleGroup] ?? [];
    final lowerMessage = message.toLowerCase();
    
    for (final word in blockedWords) {
      if (lowerMessage.contains(word)) return false;
    }
    return true;
  }
  
  void _queueSpeech(String message, SpeechPriority priority, {Duration? maxAge}) {
    if (!_isEnabled || !_initialized) return;
    
    if (priority != SpeechPriority.critical && !_isRelevantMessage(message)) return;
    
    final lastSpoke = _lastSpoke[priority];
    final cooldown = _cooldowns[priority] ?? Duration.zero;
    if (lastSpoke != null && DateTime.now().difference(lastSpoke) < cooldown) return;
    
    if (priority.index < SpeechPriority.formAlert.index && _isSpeaking) {
      _tts.stop();
      _isSpeaking = false;
    }
    
    _speechQueue.add(_SpeechItem(message: message, priority: priority, maxAge: maxAge));
    _processQueue();
  }
  
  void _processQueue() {
    if (_isSpeaking || _speechQueue.isEmpty || !_isEnabled) return;
    
    final sorted = _speechQueue.toList()..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    _speechQueue.clear();
    _speechQueue.addAll(sorted);
    _speechQueue.removeWhere((item) => item.isExpired);
    
    if (_speechQueue.isEmpty) return;
    
    final item = _speechQueue.removeFirst();
    _speak(item.message, item.priority);
  }
  
  Future<void> _speak(String message, SpeechPriority priority) async {
    if (!_initialized) await init();
    
    _isSpeaking = true;
    _lastSpoke[priority] = DateTime.now();
    await _tts.speak(message);
  }
  
  // PUBLIC API
  void announceRep(int count) => _queueSpeech('$count', SpeechPriority.repCount);
  
  void announcePerfectRep(int count) {
    final phrases = ['Perfect!', 'Yes!', 'Nice!', 'Clean!'];
    _queueSpeech('$count. ${phrases[count % phrases.length]}', SpeechPriority.repCount);
  }
  
  void announceSuperRep(int count) => _queueSpeech('$count. Super rep!', SpeechPriority.repCount);
  
  void announceExercise(String name, int sets, int reps) {
    _queueSpeech('$name. $sets sets, $reps reps.', SpeechPriority.setStatus);
  }
  
  void announceSetComplete(int setNumber, int totalSets) {
    if (setNumber >= totalSets) {
      _queueSpeech('Exercise complete!', SpeechPriority.setStatus);
    } else {
      _queueSpeech('Set $setNumber done. Rest.', SpeechPriority.setStatus);
    }
  }
  
  void announceWorkoutComplete() => _queueSpeech('Workout complete!', SpeechPriority.setStatus);
  
  void giveFormWarning(String warning) {
    _queueSpeech(warning, SpeechPriority.formAlert, maxAge: Duration(seconds: 2));
  }
  
  void giveDepthWarning() => _queueSpeech('Depth!', SpeechPriority.formAlert, maxAge: Duration(seconds: 2));
  
  void announceComboMilestone(int combo) {
    if (combo == 5) _queueSpeech('5 streak!', SpeechPriority.coaching);
    else if (combo == 10) _queueSpeech('10 streak!', SpeechPriority.coaching);
    else if (combo == 15) _queueSpeech('Unstoppable!', SpeechPriority.coaching);
  }
  
  void announceComboBreak() => _queueSpeech('Reset.', SpeechPriority.coaching);
  
  void onRepComplete(int repCount, double formScore, bool isSuperRep) {
    if (isSuperRep) {
      announceSuperRep(repCount);
    } else if (formScore >= 90) {
      announcePerfectRep(repCount);
    } else {
      announceRep(repCount);
    }
  }
  
  void onHitBottom() {
    if (_currentExerciseId == null) return;
    final id = _currentExerciseId!.toLowerCase();
    
    if (id.contains('squat') || id.contains('lunge')) {
      _queueSpeech('Drive!', SpeechPriority.formAlert, maxAge: Duration(seconds: 1));
    } else if (id.contains('push') || id.contains('bench')) {
      _queueSpeech('Push!', SpeechPriority.formAlert, maxAge: Duration(seconds: 1));
    } else if (id.contains('row') || id.contains('pull')) {
      _queueSpeech('Pull!', SpeechPriority.formAlert, maxAge: Duration(seconds: 1));
    }
  }
  
  Future<void> speakNow(String message) async {
    if (!_initialized) await init();
    await _tts.speak(message);
  }
  
  Future<void> dispose() async {
    await _tts.stop();
    _speechQueue.clear();
    _initialized = false;
  }
}