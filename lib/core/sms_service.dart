import 'package:enmkit/models/relay_model.dart';
import 'package:sms_sender_background/sms_sender.dart';
import 'package:enmkit/repositories/kit_repository.dart';

class SmsService {
  final KitRepository _kitRepository;

  SmsService(this._kitRepository);

  /// Formate automatiquement un numéro de téléphone en ajoutant l'indicatif pays +237 si manquant
  String formatPhoneNumber(String phoneNumber) {
    // Nettoyer le numéro (supprimer espaces, tirets, etc.)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si le numéro commence déjà par +237, le retourner tel quel
    if (cleanNumber.startsWith('+237')) {
      return cleanNumber;
    }
    
    // Si le numéro commence par 237, ajouter le +
    if (cleanNumber.startsWith('237')) {
      return '+$cleanNumber';
    }
    
    // Si le numéro commence par 0, le remplacer par +237
    if (cleanNumber.startsWith('0')) {
      return '+237${cleanNumber.substring(1)}';
    }
    
    // Si le numéro est un numéro local (6, 7, 8, 9 chiffres), ajouter +237
    if (cleanNumber.length >= 6 && cleanNumber.length <= 9) {
      return '+237$cleanNumber';
    }
    
    // Sinon, retourner le numéro tel quel
    return cleanNumber;
  }

  /// Méthode générique pour envoyer un SMS
  Future<void> _sendCommand(String command) async {
    try {
      // 1. Récupère le numéro du kit depuis SQLite
      final kitNumber = await _kitRepository.getKitNumber();

      if (kitNumber == null || kitNumber.isEmpty) {
        throw Exception("Aucun numéro de kit défini en base de données");
      }

      // 2. Envoie le SMS
      final smsSender = SmsSender();
      final hasPermission = await smsSender.checkSmsPermission();

      if (!hasPermission) {
        await smsSender.requestSmsPermission();
      }

      final success = await smsSender.sendSms(
        phoneNumber: kitNumber,
        message: command,
        simSlot: 0, // Spécifie le slot SIM si nécessaire
      );

      if (!success) {
        throw Exception("Échec de l'envoi du SMS");
      }
    } catch (e) {
      rethrow;
    }
  }

Future<void> toggleRelay(RelayModel relay) async {
  if (relay.id == null) {
    throw Exception("L'identifiant du relais est nul");
  }

  final command = relay.isActive ? "r${relay.id}on" : "r${relay.id}off";
  await _sendCommand(command);
}


  /// Consommation actuelle
  Future<void> requestConsumption() async {
    await _sendCommand("cons");
  }

  /// Définir le premier numéro autorisé (n1:+237678123456)
  Future<void> setFirstPhoneNumber(String phone) async {
    final formattedPhone = formatPhoneNumber(phone);
    await _sendCommand("n1:$formattedPhone");
  }

  /// Définir le second numéro autorisé (n2:+237698435687)
  Future<void> setSecondPhoneNumber(String phone) async {
    final formattedPhone = formatPhoneNumber(phone);
    await _sendCommand("n2:$formattedPhone");
  }

  /// Définir consommation initiale (en:300.0)
  Future<void> setInitialConsumption(double consInitial) async {
    await _sendCommand("en:$consInitial");
  }

  /// Définir le nombre de pulsations (ip:200)
  Future<void> setPulsation(int puls) async {
    await _sendCommand("ip:$puls");
  }

  /// Demander au kit d'appliquer/committer la configuration reçue (ok)
  Future<void> applyConfiguration() async {
    await _sendCommand("ok");
  }

  /// Méthode pour maintenir la compatibilité (deprecated)
  @Deprecated('Use setFirstPhoneNumber or setSecondPhoneNumber instead')
  Future<void> setPhoneNumber(String phone) async {
    await setFirstPhoneNumber(phone);
  }

  /// Génère les messages attendus pour la vérification stricte
  Map<String, String> generateExpectedMessages({
    String? firstPhone,
    String? secondPhone,
    double? initialConsumption,
    int? pulsation,
  }) {
    final Map<String, String> expectedMessages = {};
    
    if (firstPhone != null) {
      final formattedPhone = formatPhoneNumber(firstPhone);
      expectedMessages['n1'] = "n1:$formattedPhone";
    }
    
    if (secondPhone != null) {
      final formattedPhone = formatPhoneNumber(secondPhone);
      expectedMessages['n2'] = "n2:$formattedPhone";
    }
    
    if (initialConsumption != null) {
      expectedMessages['en'] = "en:$initialConsumption";
    }
    
    if (pulsation != null) {
      expectedMessages['ip'] = "ip:$pulsation";
    }
    
    return expectedMessages;
  }

  /// Vérifie si un message d'accusé correspond exactement au message envoyé
  bool verifyAckMessage(String ackMessage, String expectedMessage) {
    // Normaliser les messages pour la comparaison (supprimer espaces, casse)
    final normalizedAck = ackMessage.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final normalizedExpected = expectedMessage.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    
    return normalizedAck.contains(normalizedExpected);
  }
}
