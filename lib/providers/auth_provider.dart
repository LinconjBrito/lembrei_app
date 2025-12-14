import 'package:flutter/material.dart';
import 'package:myapp/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

@riverpod
Stream<AuthState> authState(Ref ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
}

@riverpod
class Auth extends _$Auth {
  @override
  FutureOr<void> build() {}
  Future<void> signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
