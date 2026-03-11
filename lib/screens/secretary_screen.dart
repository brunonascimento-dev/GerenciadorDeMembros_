import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/members_provider.dart';
import '../providers/auth_provider.dart';
import '../services/pdf_service.dart';
import 'attendance_screen.dart';
import 'financial_report_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';
import '../widgets/settings_app_bar_action.dart';

class SecretaryScreen extends StatelessWidget {
  const SecretaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secretaria'),
        centerTitle: true,
        actions: [
          settingsAppBarAction(context),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.folder_shared, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text(
              'Painel da Secretaria',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // --- BOTÃO 1: NOVA CHAMADA ---
            _buildMenuButton(
              context,
              icon: Icons.playlist_add_check,
              label: 'NOVA CHAMADA',
              color: Colors.blue.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AttendanceScreen()),
                );
              },
            ),

            const SizedBox(height: 15),

            // --- BOTÃO 2: CARTA DE MEMBRO ---
            _buildMenuButton(
              context,
              icon: Icons.description,
              label: 'GERAR CARTA DE MEMBRO',
              color: Colors.orange.shade700,
              onTap: () => _showLetterDialog(context),
            ),

            const SizedBox(height: 15),

            // --- BOTÃO 3: RELATÓRIOS MENSAIS ---
            _buildMenuButton(
              context,
              icon: Icons.picture_as_pdf,
              label: 'RELATÓRIOS MENSAIS',
              color: Colors.green.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReportsScreen()),
                );
              },
            ),

            const SizedBox(height: 15),

            // --- BOTÃO 4: RELATÓRIO FINANCEIRO ---
            _buildMenuButton(
              context,
              icon: Icons.request_quote,
              label: 'RELATÓRIO FINANCEIRO',
              color: Colors.teal.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinancialReportScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
            const Divider(),

            // --- BOTÃO 6: LOGOUT ---
            _buildMenuButton(
              context,
              icon: Icons.exit_to_app,
              label: 'SAIR DO SISTEMA',
              color: Colors.red.shade700,
              onTap: () {
                _confirmLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNÇÃO ATUALIZADA: DIÁLOGO DA CARTA ---
  void _showLetterDialog(BuildContext context) {
    final txtCity = TextEditingController();
    final txtChurch = TextEditingController();

    // Variável temporária para guardar o ID selecionado
    String? selectedMemberId;

    // Busca a lista de membros atual
    final members =
        Provider.of<MembersProvider>(context, listen: false).members;

    showDialog(
      context: context,
      builder: (ctx) {
        // StatefulBuilder é necessário para o Dropdown atualizar dentro do Diálogo
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Dados da Carta'),
            content: SingleChildScrollView(
              // Evita erro se o teclado subir
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- SELEÇÃO DE MEMBRO ---
                  DropdownButtonFormField<String>(
                    isExpanded: true, // Para nomes longos não quebrarem
                    decoration: const InputDecoration(
                      labelText: 'Selecione o Membro',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: members
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child:
                                  Text(m.nome, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedMemberId = val);
                    },
                    initialValue: selectedMemberId,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                      controller: txtCity,
                      decoration: const InputDecoration(
                          labelText: 'Cidade de Destino',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(
                      controller: txtChurch,
                      decoration: const InputDecoration(
                          labelText: 'Igreja de Destino',
                          border: OutlineInputBorder())),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  // Validação simples
                  if (selectedMemberId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Por favor, selecione um membro!')));
                    return;
                  }

                  // Encontra o objeto membro completo baseado no ID
                  final member =
                      members.firstWhere((m) => m.id == selectedMemberId);

                  Navigator.pop(ctx); // Fecha a janela

                  // Gera o PDF com os dados reais
                  await PdfService().generateRecommendationLetter(
                    member: member,
                    destinationCity:
                        txtCity.text.isEmpty ? '_________' : txtCity.text,
                    destinationChurch:
                        txtChurch.text.isEmpty ? '_________' : txtChurch.text,
                  );
                },
                child: const Text('Gerar PDF'),
              ),
            ],
          );
        });
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sair"),
        content: const Text("Tem certeza que deseja desconectar?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("SAIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
      icon: Icon(icon, size: 28),
      label: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      onPressed: onTap,
    );
  }
}
