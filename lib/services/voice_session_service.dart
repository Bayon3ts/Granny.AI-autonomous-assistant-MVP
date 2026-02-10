import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class VoiceSessionService {
  static const String _tokenEndpoint =
      'https://e8d3-102-89-33-90.ngrok-free.app/session';
  Room? _room;

  EventsListener<RoomEvent>? _listener;

  bool get isConnected => _room?.connectionState == ConnectionState.connected;

  Future<void> startSession({
    required Function(bool isConnected) onConnectionChange,
    required Function(bool isTalking) onAgentSpeaking,
    required Function(String error) onError,
  }) async {
    try {
      // 1. Permissions
      final status = await Permission.microphone.request();
      debugPrint(
          '🎤 Microphone permission: ${status == PermissionStatus.granted ? "granted" : "denied"}');
      if (status != PermissionStatus.granted) {
        onError('Microphone permission denied');
        return; // Don't stop session, just return
      }

      // 2. Fetch Token
      final sessionData = await _fetchToken();
      final token = sessionData['token'];
      final url = sessionData['url'];

      if (token == null || url == null) {
        onError('Invalid session data from server');
        return; // Don't stop session, just return
      }

      // 3. Connect to Room
      _room = Room();
      _listener = _room!.createListener();

      _setUpListeners(onConnectionChange, onAgentSpeaking, onError);

      debugPrint('🔗 Connecting to LiveKit room: $url');
      await _room!.connect(
        url,
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );
      debugPrint('✅ Connected to room: ${_room!.name}');

      // 4. Enable Mic
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      debugPrint('🎙️ Local microphone enabled');

      onConnectionChange(true);

      // Session is now active - DO NOT call stopSession here!
    } catch (e) {
      debugPrint(' Error in startSession: $e');
      onError(e.toString());
      // Only stop if we actually connected
      if (_room?.connectionState == ConnectionState.connected) {
        await stopSession();
      }
    }
  }

  Future<Map<String, dynamic>> _fetchToken() async {
    try {
      final uri = Uri.parse(_tokenEndpoint);
      debugPrint('Fetching token from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  void _setUpListeners(
    Function(bool) onConnectionChange,
    Function(bool) onAgentSpeaking,
    Function(String) onError,
  ) {
    if (_listener == null) return;

    _listener!
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('❌ Room disconnected: ${event.reason}');
        onConnectionChange(false);
      })
      ..on<RoomConnectedEvent>((event) {
        debugPrint('✅ Room connected successfully');
      })
      ..on<TrackPublishedEvent>((event) {
        debugPrint(
            '🔊 Remote track published: ${event.publication.sid}, kind: ${event.publication.kind}');
      })
      ..on<TrackSubscribedEvent>((event) async {
        debugPrint(
            '🎧 Remote track subscribed: ${event.track.sid}, kind: ${event.track.kind}');

        if (event.track.kind == TrackType.AUDIO) {
          final audioTrack = event.track as RemoteAudioTrack;
          debugPrint('🔈 Starting audio playback for track: ${audioTrack.sid}');

          try {
            await audioTrack.start();
            debugPrint('✅ Audio playback started for track: ${audioTrack.sid}');
          } catch (e) {
            debugPrint('⚠️ Error starting audio playback: $e');
            // Don't call onError here - this is not critical
          }
        }
      })
      ..on<ActiveSpeakersChangedEvent>((event) {
        bool agentTalking = false;
        for (var p in event.speakers) {
          if (p.sid != _room?.localParticipant?.sid) {
            agentTalking = true;
            break;
          }
        }
        onAgentSpeaking(agentTalking);
      })
      ..on<TrackUnpublishedEvent>((event) {
        debugPrint('🔇 Remote track unpublished: ${event.publication.sid}');
      })
      ..on<ParticipantConnectedEvent>((event) {
        debugPrint('👤 Participant joined: ${event.participant.identity}');
      });
  }

  Future<void> stopSession() async {
    debugPrint('🛑 Stopping voice session...');

    try {
      await _room?.disconnect();
    } catch (e) {
      debugPrint('⚠️ Error disconnecting room: $e');
    }

    _room = null;
    _listener?.dispose();
    _listener = null;

    debugPrint('✅ Voice session stopped');
  }

  void dispose() {
    stopSession();
  }
}
