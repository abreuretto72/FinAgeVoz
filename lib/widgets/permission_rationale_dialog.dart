import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Dialog de justificativa para permissões sensíveis
/// Conforme Google Play Policy - User Data 2.3.8
class PermissionRationaleDialog {
  /// Mostra dialog explicando por que o app precisa do microfone
  /// ANTES de solicitar a permissão do sistema
  static Future<bool> showMicrophoneRationale(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Permissão de Microfone',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O FinAgeVoz precisa acessar seu microfone para:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 12),
              _BulletPoint(
                icon: Icons.attach_money,
                text: 'Processar comandos de voz para registrar despesas e receitas',
              ),
              SizedBox(height: 8),
              _BulletPoint(
                icon: Icons.calendar_today,
                text: 'Controlar a agenda por voz',
              ),
              SizedBox(height: 8),
              _BulletPoint(
                icon: Icons.medication,
                text: 'Gerenciar lembretes de medicamentos',
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.privacy_tip, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seus dados de voz NÃO são armazenados ou compartilhados.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Permitir'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Solicita permissão de microfone COM rationale
  /// Conforme exigido pela Google Play Policy
  static Future<PermissionStatus> requestMicrophoneWithRationale(
    BuildContext context,
  ) async {
    // Verificar se já tem permissão
    final status = await Permission.microphone.status;
    if (status.isGranted) return status;

    // Se foi negado permanentemente, abrir configurações
    if (status.isPermanentlyDenied) {
      final shouldOpen = await _showPermanentlyDeniedDialog(context);
      if (shouldOpen) {
        await openAppSettings();
      }
      return status;
    }

    // Mostrar rationale ANTES de solicitar
    final shouldRequest = await showMicrophoneRationale(context);
    
    if (!shouldRequest) {
      return PermissionStatus.denied;
    }

    // Solicitar permissão do sistema
    return await Permission.microphone.request();
  }

  /// Dialog quando permissão foi negada permanentemente
  static Future<bool> _showPermanentlyDeniedDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão Necessária'),
        content: const Text(
          'A permissão de microfone foi negada permanentemente.\n\n'
          'Para usar comandos de voz, você precisa habilitar a permissão '
          'nas configurações do sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Solicita permissão de câmera COM rationale
  static Future<PermissionStatus> requestCameraWithRationale(
    BuildContext context,
  ) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return status;

    if (status.isPermanentlyDenied) {
      final shouldOpen = await _showPermanentlyDeniedDialog(context);
      if (shouldOpen) {
        await openAppSettings();
      }
      return status;
    }

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.blue),
            SizedBox(width: 8),
            Text('Permissão de Câmera'),
          ],
        ),
        content: const Text(
          'O FinAgeVoz precisa acessar sua câmera para:\n\n'
          '• Capturar fotos de recibos e notas fiscais\n'
          '• Digitalizar receitas médicas\n'
          '• Anexar comprovantes de pagamento\n\n'
          'As fotos são armazenadas apenas no seu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldRequest) return PermissionStatus.denied;
    return await Permission.camera.request();
  }
}

/// Widget auxiliar para bullet points
class _BulletPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletPoint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
