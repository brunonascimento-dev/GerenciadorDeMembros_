import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login simples (pode ser expandido depois)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      developer.log('Erro ao logar: $e', name: 'AuthService');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
