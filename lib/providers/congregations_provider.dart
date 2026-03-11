import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class CongregationsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Congregation> _congregations = [];
  bool _isLoading = false;

  List<Congregation> get congregations => _congregations;
  bool get isLoading => _isLoading;

  CongregationsProvider() {
    loadCongregations();
  }

  Future<void> loadCongregations() async {
    _isLoading = true;
    notifyListeners();

    try {
      // CORREÇÃO AQUI: Mudado de 'congregations' para 'congregacoes'
      final snapshot = await _db.collection('congregacoes').get();

      _congregations = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Congregation.fromMap(data);
      }).toList();

      // Ordena por nome
      _congregations.sort((a, b) => a.nome.compareTo(b.nome));
    } catch (e) {
      debugPrint('Erro ao carregar congregações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método auxiliar para criar uma congregação
  Future<void> addCongregation(String nome, {String endereco = ''}) async {
    // CORREÇÃO AQUI TAMBÉM: Para salvar na mesma pasta correta
    final docRef = await _db.collection('congregacoes').add({
      'nome': nome,
      'endereco': endereco,
    });

    _congregations.add(
      Congregation(id: docRef.id, nome: nome, endereco: endereco),
    );
    _congregations.sort((a, b) => a.nome.compareTo(b.nome));
    notifyListeners();
  }

  Future<void> updateCongregation({
    required String id,
    required String nome,
    String? endereco,
  }) async {
    await _db.collection('congregacoes').doc(id).update({
      'nome': nome,
      'endereco': (endereco ?? '').trim(),
    });

    final index = _congregations.indexWhere((c) => c.id == id);
    if (index != -1) {
      _congregations[index] = _congregations[index].copyWith(
        nome: nome,
        endereco: (endereco ?? '').trim().isEmpty ? null : endereco!.trim(),
      );
      _congregations.sort((a, b) => a.nome.compareTo(b.nome));
      notifyListeners();
    }
  }

  Future<void> deleteCongregation(String id) async {
    await _db.collection('congregacoes').doc(id).delete();
    _congregations.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
