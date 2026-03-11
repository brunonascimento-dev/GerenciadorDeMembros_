import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/financial_entry.dart';
import '../providers/auth_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/settings_app_bar_action.dart';

class FinancialHistoryScreen extends StatefulWidget {
  const FinancialHistoryScreen({super.key});

  @override
  State<FinancialHistoryScreen> createState() => _FinancialHistoryScreenState();
}

class _FinancialHistoryScreenState extends State<FinancialHistoryScreen> {
  final PdfService _pdfService = PdfService();

  int? _selectedMonth;
  int? _selectedYear;
  String? _generatingReportId;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (auth) => auth.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Histórico Financeiro'),
          actions: [
            settingsAppBarAction(context),
          ],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acesso permitido apenas para admin (Pastor).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico Financeiro'),
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('financial_reports')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                    'Erro ao carregar histórico financeiro: ${snapshot.error}'),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final reports = docs
              .map(_FinancialHistoryItem.fromDoc)
              .where((item) => item.month >= 1 && item.month <= 12)
              .toList()
            ..sort((a, b) {
              final periodCompare = b.periodDate.compareTo(a.periodDate);
              if (periodCompare != 0) {
                return periodCompare;
              }

              final aUpdated =
                  a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bUpdated =
                  b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bUpdated.compareTo(aUpdated);
            });

          final availableYears = reports
              .map((report) => report.year)
              .where((year) => year > 0)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          final filteredReports = reports.where(_matchesFilters).toList();

          if (reports.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum relatório financeiro salvo até o momento.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final currency =
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildFilters(
                  context: context,
                  availableYears: availableYears,
                ),
              ),
              Expanded(
                child: filteredReports.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhum relatório encontrado para os filtros selecionados.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredReports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredReports[index];
                          final monthLabel = _capitalize(
                            DateFormat('MMMM', 'pt_BR').format(item.periodDate),
                          );

                          final updatedLabel = item.updatedAt == null
                              ? 'Sem registro'
                              : dateFormat.format(item.updatedAt!);

                          final isGeneratingThis =
                              _generatingReportId == item.id;

                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _generatingReportId == null
                                  ? () => _generateReportPdf(item)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.request_quote,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$monthLabel/${item.year}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isGeneratingThis)
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        else
                                          Icon(
                                            Icons.picture_as_pdf,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Atualizado em: $updatedLabel'),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Entradas: ${currency.format(item.totalIncome)}'),
                                    Text(
                                        'Despesas: ${currency.format(item.totalExpense)}'),
                                    Text(
                                      'Saldo: ${currency.format(item.balance)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: item.balance >= 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isGeneratingThis
                                          ? 'Gerando PDF...'
                                          : 'Toque para gerar o PDF deste relatório',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters({
    required BuildContext context,
    required List<int> availableYears,
  }) {
    final monthItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Todos os meses'),
      ),
      ...List.generate(12, (index) {
        final month = index + 1;
        return DropdownMenuItem<int?>(
          value: month,
          child: Text(_capitalize(
            DateFormat('MMMM', 'pt_BR').format(DateTime(2024, month)),
          )),
        );
      }),
    ];

    final yearItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('Todos os anos'),
      ),
      ...availableYears.map(
        (year) => DropdownMenuItem<int?>(
          value: year,
          child: Text(year.toString()),
        ),
      ),
    ];

    final hasFilter = _selectedMonth != null || _selectedYear != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey(
                        'month-${_selectedMonth?.toString() ?? 'all'}'),
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mês',
                      border: OutlineInputBorder(),
                    ),
                    items: monthItems,
                    onChanged: (value) {
                      setState(() => _selectedMonth = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('year-${_selectedYear?.toString() ?? 'all'}'),
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Ano',
                      border: OutlineInputBorder(),
                    ),
                    items: yearItems,
                    onChanged: (value) {
                      setState(() => _selectedYear = value);
                    },
                  ),
                ),
              ],
            ),
            if (hasFilter) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = null;
                      _selectedYear = null;
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Limpar filtros'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _matchesFilters(_FinancialHistoryItem item) {
    if (_selectedMonth != null && item.month != _selectedMonth) {
      return false;
    }

    if (_selectedYear != null && item.year != _selectedYear) {
      return false;
    }

    return true;
  }

  Future<void> _generateReportPdf(_FinancialHistoryItem item) async {
    if (_generatingReportId != null) {
      return;
    }

    setState(() => _generatingReportId = item.id);

    try {
      await _pdfService.generateFinancialReport(
        month: item.month,
        year: item.year,
        fixedIncomes: item.fixedIncomes,
        fixedExpenses: item.fixedExpenses,
        variableIncomes: item.variableIncomes,
        variableExpenses: item.variableExpenses,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _generatingReportId = null);
      }
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

class _FinancialHistoryItem {
  _FinancialHistoryItem({
    required this.id,
    required this.month,
    required this.year,
    required this.congregationId,
    required this.updatedAt,
    required this.fixedIncomes,
    required this.fixedExpenses,
    required this.variableIncomes,
    required this.variableExpenses,
    required this.totalIncome,
    required this.totalExpense,
  });

  final String id;
  final int month;
  final int year;
  final String? congregationId;
  final DateTime? updatedAt;
  final List<FinancialEntry> fixedIncomes;
  final List<FinancialEntry> fixedExpenses;
  final List<FinancialEntry> variableIncomes;
  final List<FinancialEntry> variableExpenses;
  final double totalIncome;
  final double totalExpense;

  DateTime get periodDate => DateTime(year, month);
  double get balance => totalIncome - totalExpense;

  factory _FinancialHistoryItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final fixedIncomes = _parseEntries(data['fixedIncomes']);
    final variableIncomes = _parseEntries(data['variableIncomes']);
    final fixedExpenses = _parseEntries(data['fixedExpenses']);
    final variableExpenses = _parseEntries(data['variableExpenses']);

    return _FinancialHistoryItem(
      id: doc.id,
      month: _toInt(data['month']) ?? 0,
      year: _toInt(data['year']) ?? 0,
      congregationId: _normalizeCongregationId(data['congregationId']),
      updatedAt: _toDate(data['updatedAt']),
      fixedIncomes: fixedIncomes,
      fixedExpenses: fixedExpenses,
      variableIncomes: variableIncomes,
      variableExpenses: variableExpenses,
      totalIncome: _sumEntries(fixedIncomes) + _sumEntries(variableIncomes),
      totalExpense: _sumEntries(fixedExpenses) + _sumEntries(variableExpenses),
    );
  }

  static List<FinancialEntry> _parseEntries(dynamic rawList) {
    if (rawList is! List) {
      return const [];
    }

    final entries = <FinancialEntry>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        entries.add(FinancialEntry.fromMap(item));
        continue;
      }

      if (item is Map) {
        entries.add(FinancialEntry.fromMap(Map<String, dynamic>.from(item)));
      }
    }

    return entries.where((entry) {
      return entry.description.trim().isNotEmpty && entry.amount > 0;
    }).toList();
  }

  static double _sumEntries(List<FinancialEntry> entries) {
    return entries.fold<double>(0, (total, entry) {
      return total + entry.amount;
    });
  }

  static String? _normalizeCongregationId(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
