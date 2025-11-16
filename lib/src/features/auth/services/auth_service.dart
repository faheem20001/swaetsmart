import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------------------------------------------
  // SIGN UP WITH EMAIL + PASS + PROFILE DATA
  // -------------------------------------------------------
  Future<User?> signUp(
      String email,
      String password, {
        required Map<String, dynamic> profileData,
      }) async {
    try {
      // 1️⃣ Register User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return null;

      // 2️⃣ Build user document
      Map<String, dynamic> finalData = {
        "email": email,
        "uid": user.uid,
        "createdAt": DateTime.now(),

        // scanned from ID card
        "name": profileData["name"] ?? "",
        "batch": profileData["batch"] ?? "",
        "usn": profileData["usn"] ?? "",
        "institution": profileData["institution"] ?? "",
        "profilePicUrl": profileData["profilePic"] ?? "",

        // fitness registration
        "height": profileData["height"] ?? 0,
        "weight": profileData["weight"] ?? 0,
        "gender": profileData["gender"] ?? "",
        "age": profileData["age"] ?? 0,
        "bmi": profileData["bmi"] ?? 0,
        "bmr": profileData["bmr"] ?? 0,

        // plan type
        "planType": profileData["planType"] ?? "Standard",
      };

      // 3️⃣ Save to Firestore
      await _firestore.collection("users").doc(user.uid).set(finalData);

      return user;
    } catch (e) {
      print("SIGNUP ERROR → $e");
      return null;
    }
  }

  // -------------------------------------------------------
  // LOGIN
  // -------------------------------------------------------
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("LOGIN ERROR → $e");
      return null;
    }
  }

  // -------------------------------------------------------
  // SIGN OUT
  // -------------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // -------------------------------------------------------
  // STREAM USER
  // -------------------------------------------------------
  Stream<User?> get user => _auth.authStateChanges();
}
