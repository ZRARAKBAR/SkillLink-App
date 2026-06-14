import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signUpWithEmail(String name, String email, String password, String role) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = cred.user;

      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          fullName: name,
          email: email,
          role: role,
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return "Success";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unknown error occurred.";
    }
    return null;
  }

  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      // 1. Authenticate the user with a 15-second timeout
      UserCredential cred = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      User? user = cred.user;

      if (user != null) {
        // 2. Fetch the user document from Firestore forcing strict Server Sync
        // ✅ STEP 2 FIX APPLIED: Force server source to prevent cache sync mismatches
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));

        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        } else {
          // If the document is missing in Firestore, create it so that it doesn't fail
          UserModel newUser = UserModel(
            uid: user.uid,
            fullName: "User",
            email: email,
            role: 'customer', // Default role
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
          return newUser;
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Auth Exception: ${e.message}");
      return null;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
    return null;
  }
}