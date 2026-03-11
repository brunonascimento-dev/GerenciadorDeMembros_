import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  String? id;
  String congregationId;
  DateTime date;
  String type; // 'Culto' ou 'Santa Ceia'
  List<String> presentMemberIds; // Lista com os IDs de quem foi

  EventModel({
    this.id,
    required this.congregationId,
    required this.date,
    required this.type,
    required this.presentMemberIds,
  });

  // Converte para salvar no Firebase
  Map<String, dynamic> toMap() {
    return {
      'congregationId': congregationId,
      'date': Timestamp.fromDate(date), // Firebase usa Timestamp
      'type': type,
      'presentMemberIds': presentMemberIds,
    };
  }

  // Converte do Firebase para o App
  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      congregationId: map['congregationId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'] ?? 'Culto',
      presentMemberIds: List<String>.from(map['presentMemberIds'] ?? []),
    );
  }
}