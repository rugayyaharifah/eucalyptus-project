// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> createAdminAccount({
    required String email,
    required String password,
    required String name,
    required String currentUserId,
  }) async {
    FirebaseApp? tempApp;
    UserCredential? userCredential;

    try {
      // 1. Check if the current user is super admin
      final currentUserRole = await getUserRole(currentUserId);
      if (currentUserRole != 'super_admin') {
        throw Exception('Only super admins can create admin accounts');
      }

      // 2. Initialize a temporary Firebase app
      tempApp = await Firebase.initializeApp(
        name: 'tempApp',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // 3. Create the new admin user
      userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = userCredential.user;
      if (newUser == null) throw FirebaseAuthException(code: 'user-null');

      await newUser.updateDisplayName(name);
      await newUser.reload();

      // 4. Save to Firestore
      await _firestore.collection('users').doc(newUser.uid).set({
        'uid': newUser.uid,
        'email': email,
        'name': name,
        'role': 'admin',
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newUser;
    } catch (e) {
      // Clean up if something goes wrong
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }
      rethrow;
    } finally {
      // Always sign out and delete temp app
      try {
        if (tempApp != null) {
          final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
          await tempAuth.signOut();
          await tempApp.delete();
        }
      } catch (_) {}
    }
  }


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
        'role': 'user',
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

  final authServiceProvider = Provider<AuthService>((ref) {
    return AuthService();
  });
}



