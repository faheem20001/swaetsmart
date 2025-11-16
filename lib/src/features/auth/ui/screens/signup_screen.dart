import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../../dashboard/ui/screens/dashboard_screen.dart';
import '../../../id_scan/ui/id_card_scan_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  String gender = "Male";
  String planType = "Standard";

  String? scannedName;
  String? scannedUSN;
  String? scannedProfilePicUrl;

  bool _loading = false;

  // ---------------------- SCAN ID ----------------------
  Future<void> _scanID() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IdCardScanScreen()),
    );

    if (result != null) {
      setState(() {
        scannedName = result["name"];
        scannedUSN = result["usn"];
        scannedProfilePicUrl = result["profilePic"];
      });
    }
  }

  // ---------------------- Calculations ----------------------
  double _calculateBMI(double height, double weight) {
    double h = height / 100;
    return weight / (h * h);
  }

  double _calculateBMR(double height, double weight, int age, String gender) {
    return gender == "Male"
        ? 88.36 + (13.4 * weight) + (4.8 * height) - (5.7 * age)
        : 447.6 + (9.2 * weight) + (3.1 * height) - (4.3 * age);
  }

  // ---------------------- SIGNUP ----------------------
  Future<void> _signup() async {
    if (_passwordController.text != _confirmController.text) {
      return _show("Passwords do not match");
    }

    if (scannedUSN == null) return _show("Please scan your ID card");

    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final age = int.tryParse(_ageController.text) ?? 0;

    if (height <= 0 || weight <= 0) {
      return _show("Enter valid height & weight");
    }

    final bmi = _calculateBMI(height, weight);
    final bmr = _calculateBMR(height, weight, age, gender);

    setState(() => _loading = true);

    final user = await _auth.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      profileData: {
        "name": scannedName,
        "usn": scannedUSN,
        "profilePic": scannedProfilePicUrl,
        "height": height,
        "weight": weight,
        "gender": gender,
        "age": age,
        "bmi": bmi,
        "bmr": bmr,
        "planType": planType,
      },
    );

    setState(() => _loading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _show("Signup failed");
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5EE7DF), Color(0xFFB490CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              children: [
                const Text(
                  "Create Your Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------- Card Container ----------------------
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),

                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.badge_rounded),
                        label: const Text("Scan ID Card"),
                        onPressed: _scanID,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      if (scannedName != null)
                        _idPreviewCard(),

                      const SizedBox(height: 20),

                      _field("Email", _emailController),
                      const SizedBox(height: 12),

                      _field("Height (cm)", _heightController, type: TextInputType.number),
                      const SizedBox(height: 12),

                      _field("Weight (kg)", _weightController, type: TextInputType.number),
                      const SizedBox(height: 12),

                      _field("Age", _ageController, type: TextInputType.number),
                      const SizedBox(height: 12),

                      // Gender
                      DropdownButtonFormField(
                        value: gender,
                        onChanged: (v) => setState(() => gender = v!),
                        items: const [
                          DropdownMenuItem(value: "Male", child: Text("Male")),
                          DropdownMenuItem(value: "Female", child: Text("Female")),
                        ],
                        decoration: _inputStyle("Gender"),
                      ),
                      const SizedBox(height: 12),

                      // ---------------------- Plan Selector ----------------------
                      DropdownButtonFormField(
                        value: planType,
                        onChanged: (v) => setState(() => planType = v!),
                        items: const [
                          DropdownMenuItem(value: "Standard", child: Text("Standard")),
                          DropdownMenuItem(value: "Pro", child: Text("Pro")),
                          DropdownMenuItem(value: "Ultimate", child: Text("Ultimate")),
                        ],
                        decoration: _inputStyle("Select Plan"),
                      ),

                      const SizedBox(height: 12),

                      _field("Password", _passwordController, obscure: true),
                      const SizedBox(height: 12),

                      _field("Confirm Password", _confirmController, obscure: true),
                      const SizedBox(height: 20),

                      _loading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: Colors.teal.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------- Widgets ----------------------
  Widget _idPreviewCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          if (scannedProfilePicUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(scannedProfilePicUrl!, height: 90),
            ),
          const SizedBox(height: 8),
          Text("Name: $scannedName", style: const TextStyle(color: Colors.black)),
          Text("USN: $scannedUSN", style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.black),
      decoration: _inputStyle(label),
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
