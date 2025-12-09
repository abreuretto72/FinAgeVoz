import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';

/// Tela de exclusão de conta
/// Conforme Google Play Account Deletion Policy (obrigatório desde 2024)
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_confirmController.text.trim().toUpperCase() != 'EXCLUIR') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite EXCLUIR para confirmar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmação final
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Última Confirmação'),
        content: const Text(
          'Esta ação é IRREVERSÍVEL e excluirá permanentemente:\n\n'
          '• Todas as transações financeiras\n'
          '• Eventos da agenda\n'
          '• Lembretes de medicamentos\n'
          '• Dados sincronizados na nuvem\n\n'
          'Tem certeza absoluta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SIM, EXCLUIR TUDO'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // 1. Deletar dados do Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
        } catch (e) {
          print('Erro ao deletar Firestore: $e');
          // Continua mesmo se falhar (usuário pode não ter dados na nuvem)
        }

        // 2. Deletar dados locais (Hive) - USANDO MÉTODO CORRETO
        try {
          final db = DatabaseService();
          await db.deleteAllData(); // ✅ Método completo de exclusão
        } catch (e) {
          print('Erro ao deletar dados locais: $e');
        }

        // 3. Deletar conta do Firebase Auth
        try {
          await user.delete();
        } catch (e) {
          // Se falhar (ex: precisa reautenticar), mostrar mensagem
          if (mounted) {
            setState(() => _isDeleting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erro ao excluir conta: $e\n\n'
                  'Tente fazer logout e login novamente antes de excluir.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            return;
          }
        }
      } else {
        // Usuário não está logado, apenas limpar dados locais
        final db = DatabaseService();
        await db.deleteAllData();
      }

      if (mounted) {
        // Redirecionar para tela inicial/login
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excluir Conta'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_rounded,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Atenção: Esta ação é irreversível!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ao excluir sua conta, os seguintes dados serão permanentemente removidos:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildDataItem(
              Icons.attach_money,
              'Todas as transações financeiras',
              'Receitas, despesas e categorias',
            ),
            _buildDataItem(
              Icons.calendar_today,
              'Eventos da agenda',
              'Compromissos e lembretes',
            ),
            _buildDataItem(
              Icons.medication,
              'Lembretes de medicamentos',
              'Posologias e horários',
            ),
            _buildDataItem(
              Icons.cloud,
              'Dados sincronizados na nuvem',
              'Backup no Firebase',
            ),
            _buildDataItem(
              Icons.settings,
              'Configurações e preferências',
              'Idioma, senha de voz, etc.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta ação NÃO pode ser desfeita. Seus dados não poderão ser recuperados.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Para confirmar, digite EXCLUIR (em maiúsculas):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'EXCLUIR',
                prefixIcon: Icon(Icons.keyboard),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isDeleting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Excluindo...'),
                        ],
                      )
                    : const Text(
                        'EXCLUIR MINHA CONTA PERMANENTEMENTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar e Voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
