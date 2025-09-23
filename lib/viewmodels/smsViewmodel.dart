import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/consumption_model.dart';
import 'package:enmkit/repositories/consumption_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:readsms/readsms.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsListenerViewModel extends ChangeNotifier {

  final repo_consumption=ConsumptionRepository(DBService());
  final String? kitNumber;
  late String? trustedSender; // 🔧 Numéro autorisé 
  SmsListenerViewModel({required this.kitNumber}) {
    trustedSender = _normalizeNumber(kitNumber);
    _initSmsListener();
  }
  final plugin = Readsms();
  String lastSms = "Aucun Donnée";


  Future<void> _initSmsListener() async {
    var status = await Permission.sms.request();
    if (status.isGranted) {
      plugin.read();

      plugin.smsStream.listen((event) {
        final normalizedSender = _normalizeNumber(event.sender);
        final normalizedTrusted = trustedSender;

        final isFromTrusted = normalizedTrusted == null
            ? true
            : _numbersMatch(normalizedSender, normalizedTrusted);

        if (isFromTrusted) {
          lastSms = "${event.body}";
          _processTrustedSms(event.body ?? "");
        } else {
          lastSms = "❌ SMS rejeté : ${event.body} (de: ${event.sender})";
        }
        notifyListeners(); // 🔔 Met à jour la Vue
      });
    } else {
      lastSms = "❌ Permission SMS refusée";
      notifyListeners();
    }
  }

  String? _normalizeNumber(String? number) {
    if (number == null) return null;
    // Garder uniquement les chiffres
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    // Supprimer un 00 initial (format international)
    final withoutIdd = digits.startsWith('00') ? digits.substring(2) : digits;
    // Supprimer un 0 local de tête si un indicatif pays est présent
    return withoutIdd;
  }

  bool _numbersMatch(String? a, String? b) {
    if (a == null || b == null) return false;
    // Compare sur les 8 derniers chiffres pour gérer indicatifs différents
    final aTail = a.length > 8 ? a.substring(a.length - 8) : a;
    final bTail = b.length > 8 ? b.substring(b.length - 8) : b;
    return aTail == bTail;
  }

  void _processTrustedSms(String message) {
    // 👉 Logique métier
      final kwh = double.tryParse(message);
      if (kwh != null) {
        repo_consumption.addConsumption(ConsumptionModel(kwh: kwh, timestamp: DateTime.now()));
      }

  }
}


// import 'package:flutter/foundation.dart';
// import 'package:readsms/readsms.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SmsListenerViewModel extends ChangeNotifier {
//   final Readsms _plugin = Readsms();
//   String lastSms = "Aucune Donnée";

//   /// Numéro du kit à écouter
//   String trustedSender;

//   SmsListenerViewModel({required this.trustedSender}) {
//     _initSmsListener();
//   }

//   /// Initialisation de l'écoute des SMS
//   Future<void> _initSmsListener() async {
//     var status = await Permission.sms.request();
//     if (status.isGranted) {
//       _plugin.read();
//       _plugin.smsStream.listen((event) {
//         if (event.sender == trustedSender) {
//           lastSms = "✅ SMS autorisé : ${event.body}";
//           _processTrustedSms(event.body ?? "");
//         } else {
//           lastSms = "❌ SMS rejeté : ${event.body} (de: ${event.sender})";
//         }
//         notifyListeners();
//       });
//     } else {
//       lastSms = "❌ Permission SMS refusée";
//       notifyListeners();
//     }
//   }

//   /// Logique métier pour un SMS autorisé
//   void _processTrustedSms(String message) {
//     if (_isAck(message)) {
//       debugPrint("📩 Accusé de réception reçu !");
//     }

//     final consumption = _extractConsumption(message);
//     if (consumption != null) {
//       debugPrint("⚡ Consommation détectée : $consumption kWh");
//     }

//     if (_isRelayCommand(message)) {
//       debugPrint("🔌 Commande relais détectée : $message");
//     }
//   }

//   /// Vérifie si le message contient un accusé de réception
//   bool _isAck(String message) {
//     final ackKeywords = ['ok', 'reçu', 'received'];
//     return ackKeywords.any((k) => message.toLowerCase().contains(k));
//   }

//   /// Extrait la consommation si présente (ex: "Consommation: 12.5 kWh")
//   double? _extractConsumption(String message) {
//     try {
//       final regex = RegExp(r'(\d+(\.\d+)?)\s*kWh');
//       final match = regex.firstMatch(message);
//       if (match != null) return double.tryParse(match.group(1)!);
//       return null;
//     } catch (_) {
//       return null;
//     }
//   }

//   /// Vérifie si le message contient une commande de relais
//   bool _isRelayCommand(String message) {
//     return message.contains("ON") || message.contains("OFF");
//   }
// }
