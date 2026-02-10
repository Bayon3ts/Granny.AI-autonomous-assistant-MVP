import 'dart:async';
import 'package:flutter/material.dart';
import '../services/voice_session_service.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/summary_card.dart';
import '../widgets/health_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbController;
  final VoiceSessionService _voiceService = VoiceSessionService();

  bool _wsConnected = false;
  bool _connecting = false;
  bool _isListening = false;

  String _greeting = 'Good Morning';
  final String _userName = 'Bayo';
  final String _userAge = '82';
  final String _healthStatus = 'Good';
  final List<String> _todayReminders = ['Medications', 'Appointments'];
  final List<String> _healthMetrics = ['Energy', 'Steps', 'Sleep'];
  final String _lastChatActivity = 'Yesterday: Called Sarah';
  final List<String> _recentActivities = ['Took medication'];

  final LinearGradient cardGradient = const LinearGradient(
    colors: [Color(0xFF6D74E4), Color(0xFFF6F7FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  @override
  void dispose() {
    // DON'T stop the session here - it causes premature disconnection
    // The session will be cleaned up by the service itself when needed
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _connectToServerWs() async {
    if (_connecting) return;
    setState(() => _connecting = true);

    await _voiceService.startSession(
      onConnectionChange: (connected) {
        if (mounted) {
          setState(() {
            _wsConnected = connected;
            _connecting = false;
            if (connected) {
              _isListening = true;
              _orbController.duration = const Duration(milliseconds: 1500);
            } else {
              _isListening = false;
              _orbController.duration = const Duration(milliseconds: 3200);
            }
          });
        }
      },
      onAgentSpeaking: (speaking) {
        // Optional: update UI based on speaking state if needed
      },
      onError: (error) {
        if (mounted) {
          setState(() => _connecting = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $error')));
        }
      },
    );
  }

  Future<void> _stopListening() async {
    // Only disconnect if user explicitly wants to end the session
    await _voiceService.stopSession();
    setState(() {
      _wsConnected = false;
      _isListening = false;
      _orbController.duration = const Duration(milliseconds: 3200);
    });
  }

  String _formattedDate() {
    final d = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final w = screen.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: Container(
        decoration: BoxDecoration(gradient: cardGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ).createShader(bounds),
                            child: Text(
                              '$_greeting, $_userName ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formattedDate(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.greenAccent.withOpacity(0.2)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  _isListening
                                      ? Icons.hearing
                                      : Icons.hearing_disabled,
                                  color: Colors.white,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _isListening
                                    ? 'Granny is listening…'
                                    : (_wsConnected
                                        ? 'Connected'
                                        : (_connecting
                                            ? 'Connecting…'
                                            : 'Disconnected')),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // MAIN ORB
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      // Quick tap on orb to toggle connection
                      if (!_wsConnected && !_connecting) {
                        await _connectToServerWs();
                      } else if (_wsConnected) {
                        await _stopListening();
                      }
                    },
                    child: SizedBox(
                      width: w * 0.55,
                      height: w * 0.55,
                      child: GlowingOrb(
                        controller: _orbController,
                        label: 'Talk to\nGranny AI',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Connection status indicator
                Center(
                  child: Text(
                    _wsConnected
                        ? '🟢 Connected - Tap "End Call" when done'
                        : _connecting
                            ? '🟡 Connecting...'
                            : '⚪ Tap button below to start',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // SUMMARY + HEALTH
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 160,
                        child: SummaryCard(
                          title: 'Daily Summary',
                          subtitle: 'Reminders for Today',
                          details:
                              _todayReminders.map((r) => ' • $r').join('\n'),
                          accent: const Color(0xFF6D74E4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 160,
                        child: HealthCard(
                          title: 'Health Check',
                          subtitle:
                              _healthMetrics.map((m) => ' • $m').join('\n'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Quick Access",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _quickAccessButton("Reminders", true)),
                    const SizedBox(width: 12),
                    Expanded(child: _quickAccessButton("Health", false)),
                    const SizedBox(width: 12),
                    Expanded(child: _quickAccessButton("Memory Lane", false)),
                  ],
                ),
                const SizedBox(height: 24),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                    'https://i.pravatar.cc/150?img=65'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_userName, $_userAge',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Health: $_healthStatus',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chat History',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_lastChatActivity\n${_recentActivities.map((a) => ' • $a').join('\n')}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () async {
            if (!_wsConnected && !_connecting) {
              debugPrint('🎯 User tapped: Starting session');
              await _connectToServerWs();
            } else if (_wsConnected) {
              debugPrint('🎯 User tapped: Ending session');
              await _stopListening();
            }
          },
          backgroundColor: const Color(0xFF6D74E4),
          label: Text(
            _wsConnected
                ? 'End Call'
                : (_connecting ? 'Connecting...' : 'Talk to Granny'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          icon: Icon(_wsConnected ? Icons.call_end : Icons.mic,
              color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _quickAccessButton(String label, bool active) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? const Color(0xFF6D74E4) : Colors.white,
        foregroundColor: active ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
