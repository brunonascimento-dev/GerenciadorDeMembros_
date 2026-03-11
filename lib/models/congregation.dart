class Congregation {
  final String id;
  final String nome;
  final String? endereco;

  const Congregation({
    required this.id,
    required this.nome,
    this.endereco,
  });

  Congregation copyWith({
    String? id,
    String? nome,
    String? endereco,
  }) {
    return Congregation(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
    };
  }

  factory Congregation.fromMap(Map<String, dynamic> map) {
    return Congregation(
      id: (map['id'] ?? '').toString(),
      nome: (map['nome'] ?? '').toString(),
      endereco: map['endereco']?.toString(),
    );
  }
}
