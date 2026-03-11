import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class Frequency {
  final String id;
  final DateTime data;
  final EventType tipoEvento;
  final String congregacaoId;
  final List<String> membrosPresentes;

  const Frequency({
    required this.id,
    required this.data,
    required this.tipoEvento,
    required this.congregacaoId,
    required this.membrosPresentes,
  });

  Frequency copyWith({
    String? id,
    DateTime? data,
    EventType? tipoEvento,
    String? congregacaoId,
    List<String>? membrosPresentes,
  }) {
    return Frequency(
      id: id ?? this.id,
      data: data ?? this.data,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      congregacaoId: congregacaoId ?? this.congregacaoId,
      membrosPresentes: membrosPresentes ?? this.membrosPresentes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': Timestamp.fromDate(data),
      'tipoEvento': tipoEvento.toFirestore(),
      'congregacaoId': congregacaoId,
      'membrosPresentes': membrosPresentes,
    };
  }

  factory Frequency.fromMap(Map<String, dynamic> map) {
    final membros = (map['membrosPresentes'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList(growable: false);

    return Frequency(
      id: (map['id'] ?? '').toString(),
      data: _parseDateTime(map['data']) ?? DateTime.now(),
      tipoEvento: EventTypeFirestore.fromFirestore(map['tipoEvento']),
      congregacaoId: (map['congregacaoId'] ?? '').toString(),
      membrosPresentes: membros,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Frequency &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            data == other.data &&
            tipoEvento == other.tipoEvento &&
            congregacaoId == other.congregacaoId &&
            const ListEquality<String>()
                .equals(membrosPresentes, other.membrosPresentes);
  }

  @override
  int get hashCode => Object.hash(
        id,
        data,
        tipoEvento,
        congregacaoId,
        const ListEquality<String>().hash(membrosPresentes),
      );
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
