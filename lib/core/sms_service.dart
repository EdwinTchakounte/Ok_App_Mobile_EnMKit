import 'package:enmkit/models/relay_model.dart';
import 'package:sms_sender_background/sms_sender.dart';
import 'package:enmkit/repositories/kit_repository.dart';

class SmsService {
  final KitRepository _kitRepository;

  SmsService(this._kitRepository);

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

  /// Définir numéro (par ex. num1:678123456)
  Future<void> setPhoneNumber(String phone) async {
    await _sendCommand("num:$phone");
  }

  /// Définir consommation initiale
  Future<void> setInitialConsumption(double consInitial) async {
    await _sendCommand("cons_initial:$consInitial");
  }

  /// Définir le nombre de pulsations
  Future<void> setPulsation(int puls) async {
    await _sendCommand("puls:$puls");
  }

  /// Demander au kit d'appliquer/committer la configuration reçue
  Future<void> applyConfiguration() async {
    await _sendCommand("apply_config");
  }
}
