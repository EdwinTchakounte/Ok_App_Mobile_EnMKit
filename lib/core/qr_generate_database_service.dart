import 'dart:convert';

import '../models/kit_model.dart';
import '../models/relay_model.dart';
import '../models/allowed_number_model.dart';
import '../repositories/kit_repository.dart';
import '../repositories/relay_repository.dart';
import '../repositories/allowed_number_repository.dart';

class DatabaseRegenerator {
  final KitRepository kitRepo;
  final RelayRepository relayRepo;
  final AllowedNumberRepository allowedRepo;

  DatabaseRegenerator({
    required this.kitRepo,
    required this.relayRepo,
    required this.allowedRepo,
  });

  /// Recrée la base à partir d'un JSON string
  Future<void> regenerateFromJson(String jsonText) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonText);

      // --- 1. Kit ---
      if (data.containsKey('kit')) {
        final kitData = data['kit'] as Map<String, dynamic>;
        final kit = KitModel.fromMap(kitData);
        await kitRepo.clearKit(); // vide l'ancienne table si nécessaire
        await kitRepo.addKit(kit);
      }

      // --- 2. Relays ---
      if (data.containsKey('relays')) {
        final relaysData = data['relays'] as List<dynamic>;
        await relayRepo.clearRelays(); // vide l'ancienne table
        for (var r in relaysData) {
          final relay = RelayModel.fromMap(r as Map<String, dynamic>);
          await relayRepo.addRelay(relay);
        }
      }

      // --- 3. Allowed Users ---
      if (data.containsKey('allowedUsers')) {
        final usersData = data['allowedUsers'] as List<dynamic>;
        await allowedRepo.clearAllowedNumbers();
        for (var u in usersData) {
          final user = AllowedNumberModel.fromMap(u as Map<String, dynamic>);
          await allowedRepo.addNumber(user);
        }
      }
    } catch (e) {
      throw Exception("Erreur lors de la régénération de la base : $e");
    }
  }
}
