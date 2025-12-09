import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../l10n/app_localizations.dart';
import '../services/attachments_service.dart';

/// Diálogo de gerenciamento de anexos (Receitas, Bulas, etc.)
/// 
/// ✅ REFATORADO: Todas as strings agora usam AppLocalizations
class AttachmentsDialog extends StatefulWidget {
  final List<String> initialAttachments;
  final Future<void> Function(List<String> updatedAttachments) onSave;

  const AttachmentsDialog({
    super.key,
    required this.initialAttachments,
    required this.onSave,
  });

  @override
  State<AttachmentsDialog> createState() => _AttachmentsDialogState();
}

class _AttachmentsDialogState extends State<AttachmentsDialog> {
  final ImagePicker _picker = ImagePicker();
  List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.initialAttachments);
  }

  Future<void> _addFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final savedPath = await AttachmentsService.saveAttachment(File(photo.path));
        _updateAttachments(savedPath);
      }
    } catch (e) {
      // ✅ CORREÇÃO: Mensagem de erro ainda hardcoded - deve ser internacionalizada
      _showError('Erro ao abrir câmera: $e');
    }
  }

  Future<void> _addFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final savedPath = await AttachmentsService.saveAttachment(File(image.path));
        _updateAttachments(savedPath);
      }
    } catch (e) {
      _showError('Erro ao abrir galeria: $e');
    }
  }

  Future<void> _addFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final savedPath = await AttachmentsService.saveAttachment(File(result.files.single.path!));
        _updateAttachments(savedPath);
      }
    } catch (e) {
      _showError('Erro ao selecionar arquivo: $e');
    }
  }

  Future<void> _updateAttachments(String newPath) async {
    setState(() {
      _attachments.add(newPath);
    });
    await widget.onSave(_attachments);
  }

  Future<void> _deleteAttachment(String filePath) async {
    await AttachmentsService.deleteAttachment(filePath);
    setState(() {
      _attachments.remove(filePath);
    });
    await widget.onSave(_attachments);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddOptions() {
    // ✅ CORREÇÃO: Obter localizations uma vez
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.camera),  // ✅ INTERNACIONALIZADO
              onTap: () {
                Navigator.pop(context);
                _addFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.gallery),  // ✅ INTERNACIONALIZADO
              onTap: () {
                Navigator.pop(context);
                _addFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(l10n.file),  // ✅ INTERNACIONALIZADO
              onTap: () {
                Navigator.pop(context);
                _addFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORREÇÃO: Obter localizations
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.attachments),  // ✅ INTERNACIONALIZADO
      content: SizedBox(
        width: double.maxFinite,
        child: _attachments.isEmpty
            ? Center(child: Text('Nenhum anexo.'))  // TODO: Adicionar ao ARB
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _attachments.length,
                itemBuilder: (context, index) {
                  final filePath = _attachments[index];
                  final fileName = AttachmentsService.getFileName(filePath);
                  final isImage = ['.jpg', '.jpeg', '.png'].contains(path.extension(filePath).toLowerCase());

                  return ListTile(
                    leading: isImage
                        ? Image.file(File(filePath), width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(fileName),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAttachment(filePath),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.add),  // ✅ INTERNACIONALIZADO
          onPressed: _showAddOptions,
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),  // ✅ INTERNACIONALIZADO
        ),
      ],
    );
  }
}
