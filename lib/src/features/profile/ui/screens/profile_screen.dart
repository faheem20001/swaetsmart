import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';
import '../../models/user_fitness_model.dart';
import 'height_weight_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserFitnessModel? _fitnessData;
  Map<String, dynamic>? _profileData;
  bool _loading = true;

  final _userService = UserService();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final snap = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    final fdata = await _userService.getUserFitnessData();

    setState(() {
      _profileData = snap.data();
      _fitnessData = fdata;
      _loading = false;
    });
  }

  // ================================================================
  //    Upload Profile Picture (FULLY FIXED)
  // ================================================================
  Future<void> _uploadProfilePic() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      final file = File(picked.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child("users")
          .child(uid)
          .child("profile.jpg");

      await ref.putFile(file, SettableMetadata(cacheControl: "no-cache"));

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "profilePic": url,
      });

      setState(() => _profileData!["profilePic"] = url);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Profile Updated")));
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ================================================================
  //    PLAN UPGRADE (Mock UI)
  // ================================================================
  void _openUpgradePlan() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Upgrade Plan",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

              _planButton("Standard", Colors.green),
              const SizedBox(height: 10),
              _planButton("Pro", Colors.blue),
              const SizedBox(height: 10),
              _planButton("Ultimate", Colors.purple),
            ],
          ),
        );
      },
    );
  }

  Widget _planButton(String plan, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () async {
        Navigator.pop(context);

        await FirebaseFirestore.instance.collection("users").doc(uid).update({
          "planType": plan,
        });

        setState(() => _profileData!["planType"] = plan);

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("$plan Activated!")));
      },
      child: Text("Select $plan", style: const TextStyle(fontSize: 18)),
    );
  }

  // ================================================================
  // UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final name = _profileData?["name"] ?? "SweatSmart User";
    final usn = _profileData?["usn"] ?? "—";
    final plan = _profileData?["planType"] ?? "Standard";
    final profilePic = _profileData?["profilePic"];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ---------------------------------------------------
          // Header card
          // ---------------------------------------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.lightGreen.shade300,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _uploadProfilePic,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                    profilePic != null ? NetworkImage(profilePic) : null,
                    backgroundColor: Colors.white,
                    child: profilePic == null
                        ? const Icon(Icons.person, size: 60, color: Colors.green)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "USN: $usn",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          _sectionTitle("Account"),
          _infoCard([
            _infoTile("Name", name),
            _infoTile("USN", usn),
            _infoTile("Plan", plan),
          ]),

          const SizedBox(height: 25),

          _sectionTitle("Fitness Data"),
          if (_fitnessData != null)
            _infoCard([
              _infoTile("Height", "${_fitnessData!.height} cm"),
              _infoTile("Weight", "${_fitnessData!.weight} kg"),
              _infoTile("Age", "${_fitnessData!.age}"),
              _infoTile("Gender", _fitnessData!.gender),
              _infoTile("BMI", _fitnessData!.bmi.toStringAsFixed(2)),
              _infoTile("BMR", "${_fitnessData!.bmr.toStringAsFixed(0)} kcal/day"),
            ])
          else
            const Text("No data added yet", style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 25),

          ElevatedButton.icon(
            icon: const Icon(Icons.upgrade),
            label: const Text("Upgrade Plan"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.indigo,
            ),
            onPressed: _openUpgradePlan,
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            icon: const Icon(Icons.monitor_weight),
            label: const Text("Update Height & Weight"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HeightWeightScreen()),
              );
              _loadData();
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // UI Helpers
  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: Colors.black54, fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
