import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatar a data (dd/MM/yyyy)
import '../models/event_model.dart';
import '../models/models.dart'; // Para acessar o modelo Member e Congregation
import '../providers/congregations_provider.dart';
import '../providers/members_provider.dart';
import '../providers/frequency_provider.dart';
import '../widgets/settings_app_bar_action.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Culto'; // Padrão
  String? _selectedCongregationId;

  // Lista temporária para guardar os IDs de quem está presente nesta chamada
  final List<String> _presentMemberIds = [];

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    // Acessando os providers
    final congregationsProvider = Provider.of<CongregationsProvider>(context);
    final membersProvider = Provider.of<MembersProvider>(context);
    final frequencyProvider = Provider.of<FrequencyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Chamada'),
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- SELEÇÃO DE DATA E TIPO ---
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data do Evento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child:
                          Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Culto', 'Santa Ceia', 'EBD'].map((String tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- SELEÇÃO DE CONGREGAÇÃO ---
            DropdownButtonFormField<String>(
              initialValue: _selectedCongregationId,
              decoration: const InputDecoration(
                labelText: 'Selecione a Congregação',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.church),
              ),
              items: congregationsProvider.congregations.map((Congregation c) {
                return DropdownMenuItem(value: c.id, child: Text(c.nome));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCongregationId = val;
                  _presentMemberIds.clear();
                });
              },
            ),

            const SizedBox(height: 10),

            // --- CABEÇALHO DA LISTA ---
            if (_selectedCongregationId != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Marque quem está presente:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: ${_presentMemberIds.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

            // --- LISTA DE MEMBROS (CHECKBOXES) ---
            Expanded(
              child: _buildMembersList(membersProvider),
            ),

            // --- BOTÃO SALVAR ---
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving || _selectedCongregationId == null
                    ? null
                    : () => _saveCall(frequencyProvider),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'SALVAR CHAMADA'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget separado para construir a lista filtrada
  Widget _buildMembersList(MembersProvider provider) {
    if (_selectedCongregationId == null) {
      return const Center(
          child: Text('Selecione uma congregação acima para ver a lista.'));
    }

    // Filtra apenas membros da congregação selecionada
    final filteredMembers = provider.members
        .where((m) => m.congregacaoId == _selectedCongregationId)
        .toList();

    if (filteredMembers.isEmpty) {
      return const Center(
          child: Text('Nenhum membro cadastrado nesta congregação.'));
    }

    return ListView.builder(
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        final isSelected = _presentMemberIds.contains(member.id);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: CheckboxListTile(
            title: Text(member.nome),
            subtitle: Text(member.cargo ?? 'Sem cargo'),
            value: isSelected,
            activeColor: Colors.green,
            onChanged: (bool? checked) {
              setState(() {
                if (checked == true) {
                  _presentMemberIds.add(member.id!);
                } else {
                  _presentMemberIds.remove(member.id);
                }
              });
            },
          ),
        );
      },
    );
  }

  // Função para abrir o calendário
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // Função de Salvar
  Future<void> _saveCall(FrequencyProvider provider) async {
    if (_presentMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Marque pelo menos um membro ou justifique a ausência.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newEvent = EventModel(
        congregationId: _selectedCongregationId!,
        date: _selectedDate,
        type: _selectedType,
        presentMemberIds: _presentMemberIds,
      );

      await provider.saveEvent(newEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Chamada salva com sucesso!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Fecha a tela
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
