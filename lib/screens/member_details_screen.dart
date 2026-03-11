import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/congregations_provider.dart';
import '../providers/members_provider.dart';
import '../widgets/settings_app_bar_action.dart';

class MemberDetailsScreen extends StatefulWidget {
  const MemberDetailsScreen({super.key, required this.member});

  final Member member;

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _cargoController;
  late DateTime? _dataNascimento;
  late DateTime? _dataBatismo;
  late String _selectedCongregationId;
  late MemberStatus _selectedStatus;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.member.nome);
    _cargoController = TextEditingController(text: widget.member.cargo ?? '');
    _dataNascimento = widget.member.dataNascimento;
    _dataBatismo = widget.member.dataBatismo;
    _selectedCongregationId = widget.member.congregacaoId;
    _selectedStatus = widget.member.status;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final allCongregations =
        Provider.of<CongregationsProvider>(context).congregations;

    List<Congregation> displayCongregations = [];
    if (user != null) {
      if (user.isAdmin) {
        displayCongregations = allCongregations;
      } else if (user.congregationId != null) {
        displayCongregations =
            allCongregations.where((c) => c.id == user.congregationId).toList();
      }
    }

    if (displayCongregations.isNotEmpty &&
        !displayCongregations.any((c) => c.id == _selectedCongregationId)) {
      _selectedCongregationId = displayCongregations.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Membro'),
        centerTitle: true,
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Digite o nome'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(
                  labelText: 'Cargo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCongregationId,
                decoration: const InputDecoration(
                  labelText: 'Congregação',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.church),
                ),
                items: displayCongregations
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.nome)))
                    .toList(),
                onChanged: user != null && !user.isAdmin
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedCongregationId = value);
                        }
                      },
                validator: (value) => value == null || value.isEmpty
                    ? 'Selecione a congregação'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MemberStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: MemberStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toFirestore()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Nascimento',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dataNascimento == null
                              ? 'Selecionar'
                              : DateFormat('dd/MM/yyyy')
                                  .format(_dataNascimento!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Batismo',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dataBatismo == null
                              ? 'Selecionar'
                              : DateFormat('dd/MM/yyyy').format(_dataBatismo!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : _saveChanges,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Salvando...' : 'SALVAR ALTERAÇÕES'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : _confirmDelete,
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(_isDeleting ? 'Excluindo...' : 'EXCLUIR MEMBRO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isNascimento) async {
    final currentDate = isNascimento ? _dataNascimento : _dataBatismo;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      if (isNascimento) {
        _dataNascimento = picked;
      } else {
        _dataBatismo = picked;
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedMember = widget.member.copyWith(
        nome: _nomeController.text.trim(),
        cargo: _cargoController.text.trim().isEmpty
            ? 'Membro'
            : _cargoController.text.trim(),
        congregacaoId: _selectedCongregationId,
        dataNascimento: _dataNascimento,
        dataBatismo: _dataBatismo,
        status: _selectedStatus,
      );

      await Provider.of<MembersProvider>(context, listen: false)
          .updateMember(updatedMember);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Membro atualizado com sucesso!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao atualizar membro: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir membro'),
        content: Text('Deseja realmente excluir ${widget.member.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true ||
        widget.member.id == null ||
        widget.member.id!.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await Provider.of<MembersProvider>(context, listen: false)
          .deleteMember(widget.member.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Membro excluído com sucesso!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao excluir membro: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
