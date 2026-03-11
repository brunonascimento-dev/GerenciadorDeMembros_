import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/financial_entry.dart';

class FinancialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _db.collection('financial_reports');

  String _docId({
    required int month,
    required int year,
    required String scope,
  }) {
    return '${scope}_${year}_$month';
  }

  Future<void> saveReport({
    required int month,
    required int year,
    required String scope,
    required String? congregationId,
    required String? userId,
    required List<FinancialEntry> fixedIncomes,
    required List<FinancialEntry> fixedExpenses,
    required List<FinancialEntry> variableIncomes,
    required List<FinancialEntry> variableExpenses,
  }) async {
    final data = {
      'month': month,
      'year': year,
      'scope': scope,
      'congregationId': congregationId,
      'userId': userId,
      'fixedIncomes': _toMapList(fixedIncomes),
      'fixedExpenses': _toMapList(fixedExpenses),
      'variableIncomes': _toMapList(variableIncomes),
      'variableExpenses': _toMapList(variableExpenses),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final id = _docId(month: month, year: year, scope: scope);
    await _reportsRef.doc(id).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> loadReport({
    required int month,
    required int year,
    required String scope,
  }) async {
    final id = _docId(month: month, year: year, scope: scope);
    final doc = await _reportsRef.doc(id).get();
    return doc.data();
  }

  Future<void> clearReport({
    required int month,
    required int year,
    required String scope,
  }) async {
    final id = _docId(month: month, year: year, scope: scope);
    await _reportsRef.doc(id).delete();
  }

  List<Map<String, dynamic>> _toMapList(List<FinancialEntry> entries) {
    return entries.map((entry) => entry.toMap()).toList();
  }
}
