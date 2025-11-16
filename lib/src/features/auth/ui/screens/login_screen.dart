import 'package:flutter/material.dart';
import '../../../dashboard/ui/screens/dashboard_screen.dart';
import '../../services/auth_service.dart';
import '../../../id_scan/ui/id_card_scan_screen.dart';
import 'signup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    final user = await _auth.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => loading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid login credentials")),
      );
    }
  }

  // 🔥 Login using USN scanned from ID card
  Future<void> scanAndLogin() async {
    final scanned = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IdCardScanScreen()),
    );

    if (scanned == null) return;

    final usn = scanned["usn"]?.toString().trim().toUpperCase();

    if (usn == null || usn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid USN detected. Try again.")),
      );
      return;
    }

    setState(() => loading = true);

    // 🔎 Find user with matching USN
    final query = await FirebaseFirestore.instance
        .collection("users")
        .where("usn", isEqualTo: usn)
        .limit(1)
        .get();

    setState(() => loading = false);

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No user found with USN: $usn")),
      );
      return;
    }

    final userData = query.docs.first.data();
    final email = userData["email"];

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User record incomplete (no email).")),
      );
      return;
    }

    // 🔥 Auto-login without password using Firebase `signInWithEmailAndPassword`
    // but first get password? No — you do passwordless login:
    // We bypass password and directly push to Dashboard.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "SweatSmart",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // ---------------- TEXT INPUTS ----------------
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // ---------------- BUTTONS ----------------
              loading
                  ? const CircularProgressIndicator()
                  : Column(
                children: [
                  ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Login"),
                  ),
                  const SizedBox(height: 12),

                  // 🔥 ID Scan Login Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.teal),
                    label: const Text(
                      "Login with ID Card",
                      style: TextStyle(color: Colors.teal),
                    ),
                    onPressed: scanAndLogin,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.teal),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text("Create a new account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
