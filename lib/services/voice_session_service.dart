import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class VoiceSessionService {
  // Update this URL to point to your Python server address
  // Use 10.0.2.2 for Android Emulator, or local LAN IP for physical device
  static const String _tokenEndpoint = 'http://10.212.120.234:8080/session';

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
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission denied');
      }

      // 2. Fetch Token
      final sessionData = await _fetchToken();
      final token = sessionData['token'];
      final url = sessionData['url'];

      if (token == null || url == null) {
        throw Exception('Invalid session data from server');
      }

      // 3. Connect to Room
      _room = Room();
      _listener = _room!.createListener();

      _setUpListeners(onConnectionChange, onAgentSpeaking);

      await _room!.connect(url, token,
          roomOptions: const RoomOptions(
            adaptiveStream: true,
            dynacast: true,
          ));

      // 4. Enable Mic
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      onConnectionChange(true);
    } catch (e) {
      onError(e.toString());
      await stopSession();
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
  ) {
    if (_listener == null) return;

    _listener!
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('VoiceSessionService: Room disconnected');
        onConnectionChange(false);
      })
      ..on<ActiveSpeakersChangedEvent>((event) {
        bool agentTalking = false;
        // Check if anyone OTHER than local participant is speaking
        for (var p in event.speakers) {
          if (p.sid != _room?.localParticipant?.sid) {
            agentTalking = true;
            break;
          }
        }
        onAgentSpeaking(agentTalking);
      });
  }

  Future<void> stopSession() async {
    await _room?.disconnect();
    _room = null;
    _listener?.dispose();
    _listener = null;
  }
}
