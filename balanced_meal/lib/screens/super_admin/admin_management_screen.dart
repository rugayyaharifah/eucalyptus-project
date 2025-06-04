import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balanced_meal/services/auth_service.dart';
import 'package:balanced_meal/core/routes.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAdmin() async {
    final authService = ref.read(AuthService().authServiceProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (_formKey.currentState!.validate() && currentUserId != null) {
      setState(() => _isLoading = true);

      try {
        await authService.createAdminAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text,
          currentUserId: currentUserId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin created successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create admin: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password')),
              TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _createAdmin,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Admin'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.home, color: Colors.white,),
                label: const Text('Go to Home', style: TextStyle(color: Colors.white),),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
