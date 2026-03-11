import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class FrequencyProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Salvar uma nova chamada (Lista de presença)
  Future<void> saveEvent(EventModel event) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.collection('events').add(event.toMap());
      debugPrint("Evento salvo com sucesso!");
    } catch (e) {
      debugPrint("Erro ao salvar evento: $e");
      rethrow; // Passa o erro para quem chamou tratar (ex: mostrar snackbar)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Buscar eventos de um mês específico para o Relatório
  Future<List<EventModel>> getEventsByMonth(
      String congregationId, int month, int year) async {
    try {
      // Data inicial: dia 1 do mês selecionado
      final start = DateTime(year, month, 1);
      // Data final: dia 1 do mês seguinte (para pegar até o último segundo do mês atual)
      final end = DateTime(year, month + 1, 1);

      final snapshot = await _db
          .collection('events')
          .where('congregationId', isEqualTo: congregationId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar relatórios: $e");
      return [];
    }
  }
}
