import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/members_provider.dart';
import '../providers/congregations_provider.dart';
import '../providers/auth_provider.dart'; // <--- Importante para checar o usuário
import '../widgets/settings_app_bar_action.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _nomeController = TextEditingController();
  final _cargoController = TextEditingController(); // Ex: Membro, Diácono, etc.

  // Variáveis de estado
  String? _selectedCongregationId;
  DateTime? _dataNascimento;
  DateTime? _dataBatismo;
  bool _isLoading = false;

  // Função para limpar tudo após salvar
  void _resetForm() {
    _nomeController.clear();
    _cargoController.clear();
    setState(() {
      _selectedCongregationId = null;
      _dataNascimento = null;
      _dataBatismo = null;
    });
  }

  // Seletor de Data
  Future<void> _pickDate(bool isNascimento) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isNascimento) {
          _dataNascimento = picked;
        } else {
          _dataBatismo = picked;
        }
      });
    }
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificação extra de congregação (caso o validador do form falhe)
    if (_selectedCongregationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma congregação!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newMember = Member(
        nome: _nomeController.text.trim(),
        cargo: _cargoController.text.isEmpty
            ? 'Membro'
            : _cargoController.text.trim(),
        congregacaoId: _selectedCongregationId!, // Garantido pelo if acima
        dataNascimento: _dataNascimento,
        dataBatismo: _dataBatismo,
        status: MemberStatus.ativo,
      );

      await Provider.of<MembersProvider>(context, listen: false)
          .addMember(newMember);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Membro cadastrado com sucesso!'),
              backgroundColor: Colors.green),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Pega o usuário logado e a lista total de congregações
    final user = Provider.of<AuthProvider>(context).currentUser;
    final allCongregations =
        Provider.of<CongregationsProvider>(context).congregations;

    // 2. Filtra a lista baseada no cargo
    List<Congregation> displayCongregations = [];

    if (user != null) {
      if (user.isAdmin) {
        // Pastor vê tudo
        displayCongregations = allCongregations;
      } else if (user.congregationId != null) {
        // Líder vê só a sua igreja
        displayCongregations =
            allCongregations.where((c) => c.id == user.congregationId).toList();

        // AUTO-SELEÇÃO: Se o líder entrar e a lista tiver só 1 item, já seleciona automático
        if (_selectedCongregationId == null &&
            displayCongregations.isNotEmpty) {
          _selectedCongregationId = displayCongregations.first.id;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Cadastro"),
        centerTitle: true,
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1,
                  size: 60, color: Colors.blueGrey),
              const SizedBox(height: 20),

              // Campo Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                    labelText: 'Nome Completo', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite o nome' : null,
              ),
              const SizedBox(height: 16),

              // Campo Cargo
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(
                    labelText: 'Cargo (ex: Membro, Diácono)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // --- DROPDOWN INTELIGENTE ---
              DropdownButtonFormField<String>(
                initialValue: _selectedCongregationId,
                decoration: const InputDecoration(
                  labelText: 'Congregação',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.church),
                ),
                items: displayCongregations.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.nome));
                }).toList(),
                onChanged: user != null && !user.isAdmin
                    ? null // Se for líder, bloqueia a mudança (fica cinza mas selecionado) ou deixa mudar se tiver >1
                    : (value) =>
                        setState(() => _selectedCongregationId = value),
                validator: (value) =>
                    value == null ? 'Selecione a congregação' : null,
                // Dica visual: se for líder, mostramos o dropdown desabilitado (cinza) pq só tem uma opção
                disabledHint: _selectedCongregationId != null &&
                        displayCongregations.isNotEmpty
                    ? Text(displayCongregations.first.nome)
                    : null,
              ),
              // -----------------------------

              const SizedBox(height: 16),

              // Datas (Nascimento e Batismo)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Nascimento',
                            border: OutlineInputBorder()),
                        child: Text(_dataNascimento == null
                            ? 'Selecionar'
                            : DateFormat('dd/MM/yyyy')
                                .format(_dataNascimento!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Batismo', border: OutlineInputBorder()),
                        child: Text(_dataBatismo == null
                            ? 'Selecionar'
                            : DateFormat('dd/MM/yyyy').format(_dataBatismo!)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveMember,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Salvando...' : 'CADASTRAR MEMBRO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
