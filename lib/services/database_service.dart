import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- COLEÇÕES ---
  CollectionReference get _membersRef => _db.collection('members');
  CollectionReference get _frequenciesRef => _db.collection('frequencies');

  // --- MEMBROS ---

  // Leitura em Tempo Real (Stream)
  Stream<List<Member>> getMembers() {
    return _membersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // IMPORTANTE: Injetamos o ID do documento dentro do mapa antes de converter
        data['id'] = doc.id; 
        return Member.fromMap(data);
      }).toList();
    });
  }

  // Adicionar Membro
  Future<void> addMember(Member member) async {
    // Remove o ID do mapa, pois o Firestore gera um novo
    final map = member.toMap();
    map.remove('id'); 
    await _membersRef.add(map);
  }

  // Atualizar Membro (ex: editar nome, cargo)
  Future<void> updateMember(Member member) async {
    final map = member.toMap();
    map.remove('id'); // Não precisamos atualizar o ID dentro do documento
    await _membersRef.doc(member.id).update(map);
  }
  
  // Atualizar Status Rápido (Presença/Santa Ceia será via Frequência, mas se quiser flag no usuário):
  // Nota: Para Santa Ceia e Presença, o ideal é usar a coleção de 'Frequencies',
  // mas se você tiver campos booleanos simples no membro para controle rápido, use este:
  Future<void> updateMemberField(String memberId, String field, dynamic value) async {
    await _membersRef.doc(memberId).update({field: value});
  }

  // --- FREQUÊNCIA / PRESENÇA ---
  
  Future<void> saveFrequency(Frequency frequency) async {
    final map = frequency.toMap();
    if (frequency.id.isEmpty) {
      map.remove('id');
      await _frequenciesRef.add(map);
    } else {
      await _frequenciesRef.doc(frequency.id).set(map);
    }
  }
}
