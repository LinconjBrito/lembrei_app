import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<AuthState> authState(Ref ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.onAuthStateChange;
}

@riverpod
class Auth extends _$Auth {
  @override
  FutureOr<void> build() {}
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
