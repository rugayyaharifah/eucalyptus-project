// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String role, 
  }) async {
    try {
      debugPrint('Starting registration for $email');

      // 1. Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) throw FirebaseAuthException(code: 'user-null');

      await FirebaseAuth.instance
          .authStateChanges()
          .first; // ensure user is loaded
      // 3. Verify auth state is ready
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != user.uid) {
        throw Exception('Auth state not synchronized');
      }

       await currentUser.updateDisplayName(name);
      debugPrint("Display name updated to: ${currentUser.displayName}");


      // 2. Create Firestore document
      final userDoc =
          _firestore.collection('users').doc(userCredential.user!.uid);
      await userDoc.set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Firestore document created at users/${userDoc.id}');

      return userCredential.user; // this
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE AUTH ERROR: ${e.code} - ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('FIRESTORE ERROR: ${e.code} - ${e.message}');
      // Rollback auth user if Firestore fails
      if (e.code == 'permission-denied') {
        try {
          await _auth.currentUser?.delete();
          debugPrint('Auth user deleted due to Firestore error');
        } catch (deleteError) {
          debugPrint('Failed to delete auth user: $deleteError');
        }
      }
      
      rethrow;
    } catch (e, stack) {
      debugPrint('UNEXPECTED ERROR: $e\n$stack');
      rethrow;
    }
  }
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'user'; // Default to 'user' if role not set
  }
}



