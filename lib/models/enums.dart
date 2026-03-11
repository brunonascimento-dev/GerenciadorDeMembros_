enum MemberStatus {
  ativo,
  inativo,
}

extension MemberStatusFirestore on MemberStatus {
  String toFirestore() {
    switch (this) {
      case MemberStatus.ativo:
        return 'Ativo';
      case MemberStatus.inativo:
        return 'Inativo';
    }
  }

  static MemberStatus fromFirestore(Object? value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    switch (raw) {
      case 'ativo':
        return MemberStatus.ativo;
      case 'inativo':
        return MemberStatus.inativo;
      default:
        return MemberStatus.ativo;
    }
  }
}

enum EventType {
  santaCeia,
  culto,
}

extension EventTypeFirestore on EventType {
  String toFirestore() {
    switch (this) {
      case EventType.santaCeia:
        return 'Santa Ceia';
      case EventType.culto:
        return 'Culto';
    }
  }

  static EventType fromFirestore(Object? value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    if (raw.contains('santa')) return EventType.santaCeia;
    if (raw.contains('culto')) return EventType.culto;
    return EventType.culto;
  }
}

