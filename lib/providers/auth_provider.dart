import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart'; // Certifique-se que criou este arquivo no passo 2

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Verifica se tem alguém logado E com os dados carregados do banco
  bool get isAuth => _currentUser != null;

  // --- FUNÇÃO DE LOGIN (NOVA) ---
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Tenta logar com email e senha no Firebase Auth
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // 2. Busca o documento de permissões na coleção 'users'
      // (Aquela que você acabou de criar no site)
      DocumentSnapshot doc =
          await _db.collection('users').doc(userCred.user!.uid).get();

      if (doc.exists) {
        // Transforma os dados do banco no nosso modelo AppUser
        _currentUser =
            AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        // Se a pessoa logou, mas você esqueceu de criar o cadastro dela no banco 'users'
        _auth.signOut(); // Desloga por segurança
        throw Exception("Usuário sem permissões cadastradas no sistema.");
      }
    } catch (e) {
      debugPrint("Erro no login: $e");
      rethrow; // Passa o erro para a tela exibir o aviso
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FUNÇÃO DE LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
