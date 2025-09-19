import 'dart:convert';
import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/repositories/relay_repository.dart';
import 'package:enmkit/repositories/allowed_number_repository.dart';

class ConfigTransferService {
  final KitRepository kitRepository;
  final RelayRepository relayRepository;
  final AllowedNumberRepository allowedNumberRepository;

  ConfigTransferService({
    required this.kitRepository,
    required this.relayRepository,
    required this.allowedNumberRepository,
  });

  Future<String> exportConfig() async {
    final kit = await kitRepository.getKit();
    final relays = await relayRepository.getAllRelays();
    final numbers = await allowedNumberRepository.getAllNumbers();

    final payload = {
      'v': 1,
      'kit': kit.isNotEmpty ? kit.first.toMap() : null,
      'relays': relays.map((e) => e.toMap()).toList(),
      'allowed_numbers': numbers.map((n) => n.toMap()).toList(),
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(payload);
  }

  Future<void> importConfig(String jsonString) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    // Kit
    final kit = decoded['kit'];
    if (kit != null) {
      await kitRepository.updateKitFromMap(kit);
    }
    // Relays
    final relays = (decoded['relays'] as List<dynamic>?) ?? [];
    for (final r in relays) {
      final model = RelayModel.fromMap(r);
      await relayRepository.updateRelay(model);
    }
    // Allowed numbers
    final numbers = (decoded['allowed_numbers'] as List<dynamic>?) ?? [];
    await allowedNumberRepository.replaceAll(numbers);
  }
}


