import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/financial_entry.dart';
import '../providers/auth_provider.dart';
import '../services/financial_service.dart';
import '../services/pdf_service.dart';
import '../widgets/settings_app_bar_action.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pdfService = PdfService();
  final _financialService = FinancialService();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isGenerating = false;
  bool _isLoadingData = false;

  final List<_FinancialField> _fixedIncomeFields = [
    _FinancialField('Dízimos'),
    _FinancialField('Ofertas'),
  ];

  final List<_FinancialField> _fixedExpenseFields = [
    _FinancialField('Água'),
    _FinancialField('Energia'),
    _FinancialField('Internet'),
    _FinancialField('Aluguel'),
  ];

  final List<_FinancialItemInput> _variableIncomes = [_FinancialItemInput()];
  final List<_FinancialItemInput> _variableExpenses = [_FinancialItemInput()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersistedData();
    });
  }

  @override
  void dispose() {
    for (final field in _fixedIncomeFields) {
      field.dispose();
    }
    for (final field in _fixedExpenseFields) {
      field.dispose();
    }
    for (final item in _variableIncomes) {
      item.dispose();
    }
    for (final item in _variableExpenses) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Financeiro'),
        centerTitle: true,
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPeriodSelectors(),
            const SizedBox(height: 16),
            if (_isLoadingData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildFixedSection('Entradas Fixas', _fixedIncomeFields),
              const SizedBox(height: 16),
              _buildFixedSection('Despesas Fixas', _fixedExpenseFields),
              const SizedBox(height: 16),
              _buildVariableSection(
                title: 'Entradas Não Fixas',
                items: _variableIncomes,
                onAdd: () =>
                    setState(() => _variableIncomes.add(_FinancialItemInput())),
                onRemove: (index) {
                  final item = _variableIncomes.removeAt(index);
                  item.dispose();
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              _buildVariableSection(
                title: 'Despesas Não Fixas',
                items: _variableExpenses,
                onAdd: () => setState(
                    () => _variableExpenses.add(_FinancialItemInput())),
                onRemove: (index) {
                  final item = _variableExpenses.removeAt(index);
                  item.dispose();
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              if (_isGenerating)
                const Center(child: CircularProgressIndicator())
              else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _resetCurrentData,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('REDEFINIR DADOS'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saveCurrentData,
                  icon: const Icon(Icons.save),
                  label: const Text('SALVAR DADOS'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('GERAR RELATÓRIO PDF'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelectors() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Mês',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem(
                    value: month,
                    child: Text(DateFormat('MMMM', 'pt_BR')
                        .format(DateTime(2024, month))),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMonth = value);
                    _loadPersistedData();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(7, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem(
                      value: year, child: Text(year.toString()));
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                    _loadPersistedData();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedSection(String title, List<_FinancialField> fields) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: field.amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: field.label,
                    border: const OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableSection({
    required String title,
    required List<_FinancialItemInput> items,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Adicionar item',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: item.descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: item.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                          border: OutlineInputBorder(),
                          prefixText: 'R\$',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          items.length == 1 ? null : () => onRemove(index),
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Remover item',
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = _collectData();
    final fixedIncomes = data.fixedIncomes;
    final fixedExpenses = data.fixedExpenses;
    final variableIncomes = data.variableIncomes;
    final variableExpenses = data.variableExpenses;

    if (fixedIncomes.isEmpty &&
        fixedExpenses.isEmpty &&
        variableIncomes.isEmpty &&
        variableExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Preencha ao menos um valor para gerar o relatório.')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      await _saveData(
        fixedIncomes: fixedIncomes,
        fixedExpenses: fixedExpenses,
        variableIncomes: variableIncomes,
        variableExpenses: variableExpenses,
      );

      await _pdfService.generateFinancialReport(
        month: _selectedMonth,
        year: _selectedYear,
        fixedIncomes: fixedIncomes,
        fixedExpenses: fixedExpenses,
        variableIncomes: variableIncomes,
        variableExpenses: variableExpenses,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _saveCurrentData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = _collectData();
    await _saveData(
      fixedIncomes: data.fixedIncomes,
      fixedExpenses: data.fixedExpenses,
      variableIncomes: data.variableIncomes,
      variableExpenses: data.variableExpenses,
      showSuccessMessage: true,
    );
  }

  Future<void> _resetCurrentData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir dados'),
        content: const Text('Deseja limpar todos os campos deste mês/ano?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final scope = user?.congregationId ?? 'global';

    await _financialService.clearReport(
      month: _selectedMonth,
      year: _selectedYear,
      scope: scope,
    );

    _applyLoadedData(null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados redefinidos com sucesso.')),
    );
  }

  Future<void> _saveData({
    required List<FinancialEntry> fixedIncomes,
    required List<FinancialEntry> fixedExpenses,
    required List<FinancialEntry> variableIncomes,
    required List<FinancialEntry> variableExpenses,
    bool showSuccessMessage = false,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final scope = user?.congregationId ?? 'global';

    await _financialService.saveReport(
      month: _selectedMonth,
      year: _selectedYear,
      scope: scope,
      congregationId: user?.congregationId,
      userId: user?.id,
      fixedIncomes: fixedIncomes,
      fixedExpenses: fixedExpenses,
      variableIncomes: variableIncomes,
      variableExpenses: variableExpenses,
    );

    if (showSuccessMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados financeiros salvos com sucesso.')),
      );
    }
  }

  Future<void> _loadPersistedData() async {
    if (!mounted) return;

    setState(() => _isLoadingData = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final scope = user?.congregationId ?? 'global';

      final data = await _financialService.loadReport(
        month: _selectedMonth,
        year: _selectedYear,
        scope: scope,
      );

      _applyLoadedData(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados financeiros: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  _FinancialData _collectData() {
    final fixedIncomes = _fixedIncomeFields
        .map((f) => FinancialEntry(
            description: f.label,
            amount: _parseCurrency(f.amountController.text)))
        .where((f) => f.amount > 0)
        .toList();

    final fixedExpenses = _fixedExpenseFields
        .map((f) => FinancialEntry(
            description: f.label,
            amount: _parseCurrency(f.amountController.text)))
        .where((f) => f.amount > 0)
        .toList();

    final variableIncomes = _variableIncomes
        .map((item) => FinancialEntry(
              description: item.descriptionController.text.trim(),
              amount: _parseCurrency(item.amountController.text),
            ))
        .where((entry) => entry.description.isNotEmpty && entry.amount > 0)
        .toList();

    final variableExpenses = _variableExpenses
        .map((item) => FinancialEntry(
              description: item.descriptionController.text.trim(),
              amount: _parseCurrency(item.amountController.text),
            ))
        .where((entry) => entry.description.isNotEmpty && entry.amount > 0)
        .toList();

    return _FinancialData(
      fixedIncomes: fixedIncomes,
      fixedExpenses: fixedExpenses,
      variableIncomes: variableIncomes,
      variableExpenses: variableExpenses,
    );
  }

  void _applyLoadedData(Map<String, dynamic>? data) {
    final fixedIncomeMap = _mapEntriesByDescription(data?['fixedIncomes']);
    final fixedExpenseMap = _mapEntriesByDescription(data?['fixedExpenses']);

    for (final field in _fixedIncomeFields) {
      final value = fixedIncomeMap[field.label] ?? 0;
      field.amountController.text = value > 0 ? _toInputCurrency(value) : '';
    }

    for (final field in _fixedExpenseFields) {
      final value = fixedExpenseMap[field.label] ?? 0;
      field.amountController.text = value > 0 ? _toInputCurrency(value) : '';
    }

    _replaceVariableItems(_variableIncomes, data?['variableIncomes']);
    _replaceVariableItems(_variableExpenses, data?['variableExpenses']);
  }

  Map<String, double> _mapEntriesByDescription(dynamic source) {
    if (source is! List) return {};
    final result = <String, double>{};
    for (final row in source) {
      if (row is Map<String, dynamic>) {
        final description = (row['description'] ?? '').toString();
        if (description.isEmpty) continue;
        result[description] = _toDouble(row['amount']);
      }
    }
    return result;
  }

  void _replaceVariableItems(List<_FinancialItemInput> target, dynamic source) {
    for (final item in target) {
      item.dispose();
    }
    target.clear();

    if (source is List) {
      for (final row in source) {
        if (row is! Map<String, dynamic>) continue;
        final description = (row['description'] ?? '').toString();
        final amount = _toDouble(row['amount']);
        if (description.isEmpty && amount <= 0) continue;

        final item = _FinancialItemInput();
        item.descriptionController.text = description;
        item.amountController.text = amount > 0 ? _toInputCurrency(amount) : '';
        target.add(item);
      }
    }

    if (target.isEmpty) {
      target.add(_FinancialItemInput());
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _toInputCurrency(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _toDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  double _parseCurrency(String raw) {
    if (raw.trim().isEmpty) return 0;
    final normalized = raw
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }
}

class _FinancialField {
  _FinancialField(this.label);

  final String label;
  final TextEditingController amountController = TextEditingController();

  void dispose() {
    amountController.dispose();
  }
}

class _FinancialItemInput {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
  }
}

class _FinancialData {
  const _FinancialData({
    required this.fixedIncomes,
    required this.fixedExpenses,
    required this.variableIncomes,
    required this.variableExpenses,
  });

  final List<FinancialEntry> fixedIncomes;
  final List<FinancialEntry> fixedExpenses;
  final List<FinancialEntry> variableIncomes;
  final List<FinancialEntry> variableExpenses;
}
