import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _trustedContactController = TextEditingController();
  
  DateTime? _selectedDate;
  
  // Custom Styles for Accessibility
  final TextStyle _labelStyle = const TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.w600, 
    color: Colors.black87
  );
  
  final TextStyle _inputStyle = const TextStyle(
    fontSize: 18, 
    color: Colors.black87
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Default to 1950 for seniors (75 years old roughly)
    final initialDate = DateTime(1950);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: "Select your birth year", // Assistive text
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6D74E4), // Brand color
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
  
  String get _formattedDate {
    if (_selectedDate == null) return "Month, Day, Year";
    final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return "${months[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}";
  }

  Future<void> _completeSetup() async {
    // Basic validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tell us your name so we can welcome you properly.', style: TextStyle(fontSize: 16))),
      );
      return;
    }
    
    if (_selectedDate == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birth date.', style: TextStyle(fontSize: 16))),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    // Store simple ISO date or calculated age? Let's store year for now or full string
    await prefs.setString('user_dob', _selectedDate!.toIso8601String());
    // Calculate approximate age just in case needed for logic later
    final age = DateTime.now().year - _selectedDate!.year;
    await prefs.setString('user_age', age.toString());
    
    await prefs.setString('emergency_contact', _trustedContactController.text.trim());
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header
              const Text(
                "Welcome to Granny.AI",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32, // Large title
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D74E4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Let's get to know you better.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.black87), // Increased size
              ),
              const SizedBox(height: 12),
              // Emotional Safety Tagline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D74E4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "Granny is here to keep you company and help you feel safe.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16, 
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF555AC0),
                    height: 1.4,
                  ),
                ),
              ),
              
              const SizedBox(height: 48),

              // NAME INPUT
              _buildAccessibleLabel("What should I call you?"),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: _inputStyle,
                decoration: _buildInputDecoration("What should Granny call you?", Icons.person_outline),
              ),

              const SizedBox(height: 24),

              // DATE OF BIRTH PICKER
              _buildAccessibleLabel("When were you born?"),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.grey.shade900, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formattedDate,
                          style: TextStyle(
                            fontSize: 18,
                            color: _selectedDate == null ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.black54),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // TRUSTED CONTACT INPUT
              _buildAccessibleLabel("Trusted Contact"),
              const SizedBox(height: 8),
              TextField(
                controller: _trustedContactController,
                style: _inputStyle,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration("Phone Number (Optional)", Icons.phone_outlined),
              ),
              const SizedBox(height: 8),
              Text(
                "Someone we can notify if you ever need help.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 48),

              // ACTION BUTTON
              SizedBox(
                height: 64, // Large touch target
                child: ElevatedButton(
                  onPressed: _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF555AC0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Come In",
                    style: TextStyle(
                      fontSize: 22, // Large font
                      color: Colors.white, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessibleLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(text, style: _labelStyle),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 18, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, color: Colors.grey.shade600, size: 28),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6D74E4), width: 2),
      ),
    );
  }
}
