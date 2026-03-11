import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/members_provider.dart';
import '../providers/auth_provider.dart'; // Importante para saber quem é o usuário
import 'member_details_screen.dart';
import 'registration_screen.dart'; // Para o botão de adicionar
import '../widgets/settings_app_bar_action.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final membersProvider = Provider.of<MembersProvider>(context);
    final user = Provider.of<AuthProvider>(context).currentUser;

    // Título dinâmico
    String titulo = "Lista de Membros";
    if (user != null && !user.isAdmin) {
      titulo = "Minha Congregação"; // Líder vê título personalizado
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        centerTitle: true,
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      body: membersProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : membersProvider.members.isEmpty
              ? const Center(child: Text("Nenhum membro encontrado."))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: membersProvider.members.length,
                  itemBuilder: (context, index) {
                    final member = membersProvider.members[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(member.nome[0].toUpperCase()),
                        ),
                        title: Text(member.nome,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(member.cargo ?? 'Membro'),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MemberDetailsScreen(member: member),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () {
          // Vai para a tela de cadastro
          // Nota: Você pode precisar ajustar o RegistrationScreen também se quiser bloquear congregação
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const RegistrationScreen()));
        },
      ),
    );
  }
}
