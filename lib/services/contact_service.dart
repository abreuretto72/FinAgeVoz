import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  bool _permissionGranted = false;

  Future<bool> requestPermission() async {
    if (_permissionGranted) return true;
    
    _permissionGranted = await FlutterContacts.requestPermission(readonly: true);
    return _permissionGranted;
  }

  Future<String?> findContactPhoneNumber(String name) async {
    if (!await requestPermission()) {
      return null;
    }

    // Normaliza o nome buscado (remove acentos e minúsculas)
    final searchName = _normalizeString(name);
    
    // Busca contatos que correspondem ao nome
    // Usamos withProperties: true para trazer os telefones
    final contacts = await FlutterContacts.getContacts(
      withProperties: true, 
      withPhoto: false
    );

    // Procura o contato mais próximo
    for (var contact in contacts) {
      final contactName = _normalizeString(contact.displayName);
      
      // Verifica se o nome contém a busca ou vice-versa
      if (contactName.contains(searchName) || searchName.contains(contactName)) {
        // Retorna o primeiro número de telefone encontrado
        if (contact.phones.isNotEmpty) {
          // Limpa o número (remove caracteres não numéricos)
          return _cleanPhoneNumber(contact.phones.first.number);
        }
      }
    }

    return null;
  }

  Future<Map<String, String>?> findFullContact(String name) async {
    if (!await requestPermission()) return null;

    final searchName = _normalizeString(name);
    final contacts = await FlutterContacts.getContacts(
      withProperties: true, 
      withPhoto: false
    );

    for (var contact in contacts) {
      final contactName = _normalizeString(contact.displayName);
      if (contactName.contains(searchName) || searchName.contains(contactName)) {
        String? phone;
        String? sms;
        String? email;
        
        // WhatsApp (Assuming first mobile is WA)
        if (contact.phones.isNotEmpty) {
           phone = _cleanPhoneNumber(contact.phones.first.number);
           sms = phone; // Assuming same for now
        }
        
        if (contact.emails.isNotEmpty) {
           email = contact.emails.first.address;
        }

        return {
           'phone': phone ?? '',
           'sms': sms ?? '',
           'email': email ?? '',
        };
      }
    }
    return null;
  }

  Future<bool> callOnWhatsApp(String phoneNumber) async {
    // Adiciona o código do país se não tiver (assumindo Brasil +55 por padrão se faltar)
    // Mas geralmente os contatos já vêm com formato variado.
    // O WhatsApp aceita números limpos com código do país.
    
    // Se o número não começar com +, e tiver 10 ou 11 dígitos, assume BR (+55)
    String finalNumber = phoneNumber;
    if (!finalNumber.startsWith('+')) {
      if (finalNumber.length >= 10 && finalNumber.length <= 11) {
        finalNumber = '55$finalNumber';
      }
    }
    
    // Remove o + para a URL do WhatsApp
    finalNumber = finalNumber.replaceAll('+', '');

    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$finalNumber");
    final Uri webUrl = Uri.parse("https://wa.me/$finalNumber");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
        return true;
      } else {
        // Fallback para web
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      print("Erro ao abrir WhatsApp: $e");
      return false;
    }
  }

  Future<bool> sendMessageOnWhatsApp(String phoneNumber, String message) async {
    String finalNumber = phoneNumber;
    if (!finalNumber.startsWith('+')) {
      if (finalNumber.length >= 10 && finalNumber.length <= 11) {
        finalNumber = '55$finalNumber';
      }
    }
    finalNumber = finalNumber.replaceAll('+', '');
    
    final encodedMsg = Uri.encodeComponent(message);
    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$finalNumber&text=$encodedMsg");
    final Uri webUrl = Uri.parse("https://wa.me/$finalNumber?text=$encodedMsg");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
        return true;
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      print("Erro ao enviar mensagem Zap: $e");
      return false;
    }
  }

  Future<Map<String, String>?> pickContact() async {
    if (!await requestPermission()) return null;
    
    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
         // Fetch full details to be sure, although pick might have them.
         // On some devices, pick returns minimal info.
         final fullContact = await FlutterContacts.getContact(contact.id);
         if (fullContact == null) return null;
         
         String? phone;
         String? email;
         
         if (fullContact.phones.isNotEmpty) {
             phone = _cleanPhoneNumber(fullContact.phones.first.number);
         }
         if (fullContact.emails.isNotEmpty) {
             email = fullContact.emails.first.address;
         }
         
         return {
            'name': fullContact.displayName,
            'phone': phone ?? '',
            'sms': phone ?? '',
            'email': email ?? '',
         };
      }
    } catch (e) {
      print("Error picking contact: $e");
    }
    return null;
  }

  String _normalizeString(String str) {
    return str.toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }
}
