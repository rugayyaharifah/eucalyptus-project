import 'package:balanced_meal/screens/home_screen.dart';
import 'package:balanced_meal/screens/login_screen.dart';
import 'package:balanced_meal/screens/super_admin/admin_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (userSnapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text('Error: ${userSnapshot.error}')),
                  );
                }

                if (userSnapshot.hasData) {
                  final role = userSnapshot.data?.get('role') ?? 'user';

                  // Redirect based on role
                  if (role == 'super_admin') {
                    return const AdminManagementScreen();
                  } else {
                    return const HomeScreen();
                  }
                }

                // Fallback for any other case
                return const HomeScreen();
              },
            );
          }
          return const LoginScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
