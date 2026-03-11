import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class Member {
   String? id;
  final String nome;
  final String? fotoUrl;
  final DateTime? dataNascimento;
  final DateTime? dataBatismo;
  final String congregacaoId;
  final MemberStatus status;
  final String? cargo;

   Member({
    this.id,
    required this.nome,
    required this.congregacaoId,
    this.fotoUrl,
    this.dataNascimento,
    this.dataBatismo,
    this.status = MemberStatus.ativo,
    this.cargo,
  });

  Member copyWith({
    String? id,
    String? nome,
    String? fotoUrl,
    DateTime? dataNascimento,
    DateTime? dataBatismo,
    String? congregacaoId,
    MemberStatus? status,
    String? cargo,
  }) {
    return Member(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      dataBatismo: dataBatismo ?? this.dataBatismo,
      congregacaoId: congregacaoId ?? this.congregacaoId,
      status: status ?? this.status,
      cargo: cargo ?? this.cargo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'fotoUrl': fotoUrl,
      'dataNascimento':
          dataNascimento == null ? null : Timestamp.fromDate(dataNascimento!),
      'dataBatismo': dataBatismo == null ? null : Timestamp.fromDate(dataBatismo!),
      'congregacaoId': congregacaoId,
      'status': status.toFirestore(),
      'cargo': cargo,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: (map['id'] ?? '').toString(),
      nome: (map['nome'] ?? '').toString(),
      fotoUrl: map['fotoUrl']?.toString(),
      dataNascimento: _parseDateTime(map['dataNascimento']),
      dataBatismo: _parseDateTime(map['dataBatismo']),
      congregacaoId: (map['congregacaoId'] ?? '').toString(),
      status: MemberStatusFirestore.fromFirestore(map['status']),
      cargo: map['cargo']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Member &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            nome == other.nome &&
            fotoUrl == other.fotoUrl &&
            dataNascimento == other.dataNascimento &&
            dataBatismo == other.dataBatismo &&
            congregacaoId == other.congregacaoId &&
            status == other.status &&
            cargo == other.cargo;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nome,
        fotoUrl,
        dataNascimento,
        dataBatismo,
        congregacaoId,
        status,
        cargo,
      );
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    return parsed;
  }
  return null;
}
