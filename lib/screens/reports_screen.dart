import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/congregations_provider.dart';
import '../providers/members_provider.dart';
import '../providers/frequency_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/settings_app_bar_action.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedCongregationId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final PdfService _pdfService = PdfService();

  @override
  Widget build(BuildContext context) {
    // Busca a lista de congregações
    final congregations =
        Provider.of<CongregationsProvider>(context).congregations;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Relatórios Mensais"),
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Selecione os dados para o relatório:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Seleção de Congregação
            DropdownButtonFormField<String>(
              initialValue: _selectedCongregationId,
              decoration: const InputDecoration(
                  labelText: 'Congregação', border: OutlineInputBorder()),
              items: congregations
                  .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCongregationId = val),
            ),
            const SizedBox(height: 16),

            // Seleção de Mês e Ano
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                        labelText: 'Mês', border: OutlineInputBorder()),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(DateFormat('MMMM', 'pt_BR')
                            .format(DateTime(2024, index + 1))),
                      );
                    }),
                    onChanged: (val) => setState(() => _selectedMonth = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                        labelText: 'Ano', border: OutlineInputBorder()),
                    items: [2024, 2025, 2026, 2027]
                        .map((y) => DropdownMenuItem(
                            value: y, child: Text(y.toString())))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedYear = val!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("GERAR RELATÓRIO PDF"),
                    onPressed: _generateReport,
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    if (_selectedCongregationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma congregação!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Busca os dados dos Providers
      final frequencyProvider =
          Provider.of<FrequencyProvider>(context, listen: false);
      final membersProvider =
          Provider.of<MembersProvider>(context, listen: false);
      final congregProvider =
          Provider.of<CongregationsProvider>(context, listen: false);

      // Busca eventos do mês
      final events = await frequencyProvider.getEventsByMonth(
          _selectedCongregationId!, _selectedMonth, _selectedYear);

      // Filtra membros dessa congregação
      final members = membersProvider.members
          .where((m) => m.congregacaoId == _selectedCongregationId)
          .toList();

      // Pega o nome da congregação
      final congName = congregProvider.congregations
          .firstWhere((c) => c.id == _selectedCongregationId)
          .nome;

      if (events.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Nenhuma chamada encontrada neste mês.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Gera o PDF usando o serviço
      await _pdfService.generateMonthlyReport(
          members, events, congName, _selectedMonth, _selectedYear);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
