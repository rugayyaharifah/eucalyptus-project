// lib/screens/auth/register_screen.dart
import 'package:balanced_meal/core/routes.dart';
import 'package:balanced_meal/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
Future<void> testCompleteFlow() async {
    try {
      debugPrint('=== STARTING ATOMIC TEST ===');

      // 1. Auth Test
      debugPrint('Creating auth user...');
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test${DateTime.now().millisecondsSinceEpoch}@test.com',
        password: 'password123',
      );
      debugPrint('✅ Auth success! UID: ${cred.user?.uid}');

      // 2. Immediate Firestore Write
      debugPrint('Writing to Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Firestore write success!');

      // 3. Verify Document
      debugPrint('Reading back document...');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();
      debugPrint('✅ Document exists: ${doc.exists}');
    } catch (e, stack) {
      debugPrint('🚨 CRITICAL ERROR: $e');
      debugPrint('Stack trace: $stack');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) =>
                    value!.length < 6 ? 'Min 6 characters' : null,
              ),
              ElevatedButton(
  onPressed: () async {
    try {
      final user = await AuthService().registerUser(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );
      
      if (user != null && context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    }
  },
  child: const Text('Register'),
),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
