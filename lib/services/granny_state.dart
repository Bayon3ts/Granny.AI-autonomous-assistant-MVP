/// Canonical Voice State Machine for Granny.AI
/// 
/// All layers (UI, audio, backend) subscribe to this state.
/// State changes must be explicit, logged, and observable.
library;

import 'package:flutter/foundation.dart';

/// The six canonical states of Granny's voice pipeline.
/// 
/// IMPORTANT: These states are shared between Flutter and Python.
/// Any changes here must be mirrored in agent.py.
enum GrannyState {
  /// Calm resting state. No mic, no network calls.
  /// Orb: slow breathing glow (3200ms cycle)
  idle,

  /// Mic open, waiting for speech. Slightly brighter steady glow.
  /// Timeout → idle after 30s of silence.
  listening,

  /// Actively receiving audio frames from user.
  /// Orb reacts subtly to voice amplitude (smooth dampening).
  /// Fully local - no network dependency.
  userSpeaking,

  /// ASR locked, LLM request in flight.
  /// Orb shows gentle shimmer. Granny may acknowledge verbally.
  /// If >1.2s, reassurance audio plays.
  thinking,

  /// Audio playback active. Warm pulse synced to speech.
  /// Supports streaming TTS.
  grannySpeaking,

  /// Provider failure detected. Calm neutral glow.
  /// Silent recovery attempt. If fails → apology → idle.
  errorRecovering,
}

/// Extension for state metadata and logging
extension GrannyStateExtension on GrannyState {
  /// Human-readable name for logging
  String get displayName {
    switch (this) {
      case GrannyState.idle:
        return 'IDLE';
      case GrannyState.listening:
        return 'LISTENING';
      case GrannyState.userSpeaking:
        return 'USER_SPEAKING';
      case GrannyState.thinking:
        return 'THINKING';
      case GrannyState.grannySpeaking:
        return 'GRANNY_SPEAKING';
      case GrannyState.errorRecovering:
        return 'ERROR_RECOVERING';
    }
  }

  /// Emoji prefix for console logging
  String get logEmoji {
    switch (this) {
      case GrannyState.idle:
        return '😴';
      case GrannyState.listening:
        return '👂';
      case GrannyState.userSpeaking:
        return '🗣️';
      case GrannyState.thinking:
        return '🧠';
      case GrannyState.grannySpeaking:
        return '👵';
      case GrannyState.errorRecovering:
        return '🔄';
    }
  }

  /// Whether mic should be capturing in this state
  bool get isMicActive {
    switch (this) {
      case GrannyState.listening:
      case GrannyState.userSpeaking:
        return true;
      default:
        return false;
    }
  }

  /// Whether we're in an active conversation (not idle)
  bool get isSessionActive {
    return this != GrannyState.idle;
  }

  /// Animation parameters for the orb
  OrbAnimationParams get orbParams {
    switch (this) {
      case GrannyState.idle:
        return const OrbAnimationParams(
          breathDurationMs: 3200,
          glowMin: 0.2,
          glowMax: 0.5,
          haloStyle: HaloStyle.none,
          colorTemperature: ColorTemperature.neutral,
        );
      case GrannyState.listening:
        return const OrbAnimationParams(
          breathDurationMs: 2400,
          glowMin: 0.4,
          glowMax: 0.6,
          haloStyle: HaloStyle.steady,
          colorTemperature: ColorTemperature.slightlyWarm,
        );
      case GrannyState.userSpeaking:
        return const OrbAnimationParams(
          breathDurationMs: 1600,
          glowMin: 0.5,
          glowMax: 0.9,
          haloStyle: HaloStyle.none,
          colorTemperature: ColorTemperature.warm,
          reactsToAmplitude: true,
        );
      case GrannyState.thinking:
        return const OrbAnimationParams(
          breathDurationMs: 2000,
          glowMin: 0.5,
          glowMax: 0.7,
          haloStyle: HaloStyle.shimmer,
          colorTemperature: ColorTemperature.cool,
        );
      case GrannyState.grannySpeaking:
        return const OrbAnimationParams(
          breathDurationMs: 1800,
          glowMin: 0.6,
          glowMax: 0.9,
          haloStyle: HaloStyle.pulse,
          colorTemperature: ColorTemperature.warm,
          reactsToAmplitude: true,
        );
      case GrannyState.errorRecovering:
        return const OrbAnimationParams(
          breathDurationMs: 2800,
          glowMin: 0.3,
          glowMax: 0.5,
          haloStyle: HaloStyle.none,
          colorTemperature: ColorTemperature.neutral,
        );
    }
  }
}

/// Halo visual styles for the orb
enum HaloStyle {
  none,
  steady,
  shimmer,
  pulse,
}

/// Color temperature shifts for the orb
enum ColorTemperature {
  neutral,
  slightlyWarm,
  warm,
  cool,
}

/// Animation parameters for a given state
@immutable
class OrbAnimationParams {
  final int breathDurationMs;
  final double glowMin;
  final double glowMax;
  final HaloStyle haloStyle;
  final ColorTemperature colorTemperature;
  final bool reactsToAmplitude;

  const OrbAnimationParams({
    required this.breathDurationMs,
    required this.glowMin,
    required this.glowMax,
    required this.haloStyle,
    required this.colorTemperature,
    this.reactsToAmplitude = false,
  });
}

/// Validates state transitions and logs them
class GrannyStateTransition {
  /// Valid transitions from each state
  static const Map<GrannyState, Set<GrannyState>> _validTransitions = {
    GrannyState.idle: {GrannyState.listening},
    GrannyState.listening: {
      GrannyState.userSpeaking,
      GrannyState.idle, // timeout
      GrannyState.grannySpeaking, // agent initiates
      GrannyState.errorRecovering,
    },
    GrannyState.userSpeaking: {
      GrannyState.thinking,
      GrannyState.listening, // brief pause
      GrannyState.errorRecovering,
    },
    GrannyState.thinking: {
      GrannyState.grannySpeaking,
      GrannyState.errorRecovering,
      GrannyState.listening, // empty response
    },
    GrannyState.grannySpeaking: {
      GrannyState.listening,
      GrannyState.errorRecovering,
      GrannyState.idle, // session end
    },
    GrannyState.errorRecovering: {
      GrannyState.listening, // recovery success
      GrannyState.idle, // recovery failed
      GrannyState.grannySpeaking, // fallback audio playing
    },
  };

  /// Check if a transition is valid
  static bool isValid(GrannyState from, GrannyState to) {
    // Always allow staying in current state
    if (from == to) return true;
    return _validTransitions[from]?.contains(to) ?? false;
  }

  /// Log a state transition with reason
  static void log(GrannyState from, GrannyState to, String reason) {
    final isValidTransition = isValid(from, to);
    final prefix = isValidTransition ? '✅' : '⚠️ INVALID';
    
    debugPrint(
      '$prefix [STATE] ${from.logEmoji} ${from.displayName} → '
      '${to.logEmoji} ${to.displayName} | Reason: $reason'
    );

    if (!isValidTransition) {
      debugPrint('   ⚠️ Warning: Unexpected state transition!');
    }
  }
}

/// Parse state from JSON string (from data channel)
GrannyState? parseGrannyState(String stateString) {
  switch (stateString.toUpperCase()) {
    case 'IDLE':
      return GrannyState.idle;
    case 'LISTENING':
      return GrannyState.listening;
    case 'USER_SPEAKING':
      return GrannyState.userSpeaking;
    case 'THINKING':
      return GrannyState.thinking;
    case 'GRANNY_SPEAKING':
      return GrannyState.grannySpeaking;
    case 'ERROR_RECOVERING':
      return GrannyState.errorRecovering;
    default:
      debugPrint('⚠️ Unknown state string: $stateString');
      return null;
  }
}
