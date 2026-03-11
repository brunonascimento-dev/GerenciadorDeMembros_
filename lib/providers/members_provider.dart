import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../models/app_user.dart'; // Importante!

class MembersProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Member> _members = [];
  bool _isLoading = false;

  List<Member> get members => _members;
  bool get isLoading => _isLoading;

  // Agora precisa pedir ao USUÁRIO para saber o que carregar
  Future<void> loadMembers(AppUser? user) async {
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      Query query = _db.collection('members');

      // Se não for Pastor, filtra pela congregação
      if (!user.isAdmin && user.congregationId != null) {
        query = query.where('congregacaoId', isEqualTo: user.congregationId);
      }
      // Se for Admin, não faz nada (carrega tudo)

      final snapshot = await query.get();

      _members = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Member.fromMap(data);
      }).toList();

      _members.sort((a, b) => a.nome.compareTo(b.nome));
    } catch (e) {
      debugPrint('Erro ao carregar membros: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar membro (o básico)
  Future<void> addMember(Member member) async {
    try {
      final docRef = await _db.collection('members').add(member.toMap());
      member.id = docRef.id;
      _members.add(member);
      _members.sort((a, b) => a.nome.compareTo(b.nome));
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao adicionar: $e');
      rethrow;
    }
  }

  Future<void> updateMember(Member member) async {
    if (member.id == null || member.id!.isEmpty) {
      throw Exception('ID do membro inválido para atualização.');
    }

    try {
      final map = member.toMap();
      map.remove('id');
      await _db.collection('members').doc(member.id).update(map);

      final index = _members.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _members[index] = member;
        _members.sort((a, b) => a.nome.compareTo(b.nome));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar membro: $e');
      rethrow;
    }
  }

  Future<void> deleteMember(String memberId) async {
    try {
      await _db.collection('members').doc(memberId).delete();
      _members.removeWhere((m) => m.id == memberId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao excluir membro: $e');
      rethrow;
    }
  }
}
