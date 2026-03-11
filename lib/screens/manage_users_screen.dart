import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/congregations_provider.dart';
import '../services/admin_user_service.dart';
import '../widgets/settings_app_bar_action.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  Future<void> _showUserDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    final isCreate = docId == null;
    final uid = docId ?? '';

    final emailController = TextEditingController(text: data?['email'] ?? '');
    final passwordController = TextEditingController();

    String role = (data?['role'] ?? 'leader').toString();
    String? selectedCongregationId = data?['congregationId']?.toString();

    final formKey = GlobalKey<FormState>();
    final congregations =
        Provider.of<CongregationsProvider>(context, listen: false)
            .congregations;
    final adminUserService = AdminUserService();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(isCreate ? 'Novo usuário' : 'Editar usuário'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCreate) ...[
                    TextFormField(
                      initialValue: uid,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'UID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o e-mail';
                      }
                      return null;
                    },
                  ),
                  if (isCreate) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha inicial',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe a senha inicial';
                        }
                        if (value.trim().length < 6) {
                          return 'A senha deve ter ao menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(
                      labelText: 'Papel',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'leader', child: Text('Leader')),
                    ],
                    onChanged: (value) => setLocalState(() {
                      role = value ?? 'leader';
                      if (role == 'admin') {
                        selectedCongregationId = null;
                      }
                    }),
                  ),
                  if (role == 'leader') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCongregationId,
                      decoration: const InputDecoration(
                        labelText: 'Congregação',
                        border: OutlineInputBorder(),
                      ),
                      items: congregations
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.nome),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setLocalState(() {
                        selectedCongregationId = value;
                      }),
                      validator: (value) {
                        if (role == 'leader' &&
                            (value == null || value.isEmpty)) {
                          return 'Selecione uma congregação';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
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
      ),
    );

    if (saved == true && context.mounted) {
      try {
        if (isCreate) {
          await adminUserService.createUser(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            role: role,
            congregationId: selectedCongregationId,
          );
        } else {
          await adminUserService.updateUserProfile(
            uid: uid,
            email: emailController.text.trim(),
            role: role,
            congregationId: selectedCongregationId,
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCreate
                    ? 'Usuário criado com sucesso.'
                    : 'Usuário atualizado com sucesso.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar usuário: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: const Text(
          'Deseja realmente excluir este usuário no Auth e no Firestore?',
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
        await AdminUserService().deleteUser(uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário excluído com sucesso.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir usuário: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final congregationMap = {
      for (final c in Provider.of<CongregationsProvider>(context).congregations)
        c.id: c.nome,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar usuários'),
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Novo'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar usuários: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum usuário cadastrado.'));
          }

          docs.sort((a, b) {
            final emailA = (a.data()['email'] ?? '').toString();
            final emailB = (b.data()['email'] ?? '').toString();
            return emailA.compareTo(emailB);
          });

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final role = (data['role'] ?? 'leader').toString();
              final congregationId = data['congregationId']?.toString();
              final congregationName = congregationMap[congregationId] ?? '—';

              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text((data['email'] ?? '').toString()),
                subtitle: Text(
                  role == 'admin'
                      ? 'Papel: admin'
                      : 'Papel: leader • Congregação: $congregationName',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showUserDialog(
                        context,
                        docId: doc.id,
                        data: data,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Excluir',
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _confirmDelete(context, doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
