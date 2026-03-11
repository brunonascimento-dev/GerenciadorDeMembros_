import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/congregation.dart';
import '../providers/congregations_provider.dart';
import '../widgets/settings_app_bar_action.dart';

class ManageCongregationsScreen extends StatelessWidget {
  const ManageCongregationsScreen({super.key});

  Future<void> _showCongregationDialog(
    BuildContext context, {
    Congregation? congregation,
  }) async {
    final nameController =
        TextEditingController(text: congregation?.nome ?? '');
    final addressController =
        TextEditingController(text: congregation?.endereco ?? '');

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            congregation == null ? 'Nova congregação' : 'Editar congregação'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da congregação';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      final provider =
          Provider.of<CongregationsProvider>(context, listen: false);
      try {
        if (congregation == null) {
          await provider.addCongregation(
            nameController.text.trim(),
            endereco: addressController.text.trim(),
          );
        } else {
          await provider.updateCongregation(
            id: congregation.id,
            nome: nameController.text.trim(),
            endereco: addressController.text.trim(),
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                congregation == null
                    ? 'Congregação criada com sucesso.'
                    : 'Congregação atualizada com sucesso.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Congregation congregation,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir congregação'),
        content: Text(
          'Deseja realmente excluir "${congregation.nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await Provider.of<CongregationsProvider>(context, listen: false)
            .deleteCongregation(congregation.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Congregação excluída.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CongregationsProvider>(context);
    final congregations = provider.congregations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar congregações'),
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCongregationDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : congregations.isEmpty
              ? const Center(
                  child: Text('Nenhuma congregação cadastrada.'),
                )
              : ListView.separated(
                  itemCount: congregations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = congregations[index];
                    return ListTile(
                      leading: const Icon(Icons.church_outlined),
                      title: Text(c.nome),
                      subtitle: (c.endereco == null || c.endereco!.isEmpty)
                          ? null
                          : Text(c.endereco!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showCongregationDialog(
                              context,
                              congregation: c,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Excluir',
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _confirmDelete(context, c),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
