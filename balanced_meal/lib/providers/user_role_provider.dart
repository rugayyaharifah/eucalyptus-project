// lib/providers/user_role_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRoleNotifier extends StateNotifier<AsyncValue<String>> {
  UserRoleNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

 

  Future<void> _init() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = const AsyncValue.data('guest');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      state = AsyncValue.data(doc.get('role') ?? 'user');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final isSuperAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).when(
        data: (role) => role == 'super_admin',
        loading: () => false,
        error: (_, __) => false,
      );
});

final userRoleProvider = StreamProvider<String>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) => snapshot.data()?['role'] ?? 'user');
});

final isAdminProvider = Provider<bool>((ref) {
  final roleAsync = ref.watch(userRoleProvider);

  return roleAsync.when(
    data: (role) => role == 'admin' || role == 'super_admin',
    loading: () => false,
    error: (_, __) => false,
  );
});


