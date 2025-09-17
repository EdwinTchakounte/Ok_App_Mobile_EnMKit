import 'dart:convert';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:flutter/material.dart';

import '../models/kit_model.dart';
import '../models/relay_model.dart';
import '../models/allowed_number_model.dart';
import '../repositories/kit_repository.dart';
import '../repositories/relay_repository.dart';
import '../repositories/allowed_number_repository.dart';

class QrService {
  final KitRepository kitRepo;
  final RelayRepository relayRepo;
  final AllowedNumberRepository allowedRepo;

  QrService({
    required this.kitRepo,
    required this.relayRepo,
    required this.allowedRepo,
  });

  /// Génère le JSON complet pour le QR Code
  Future<String> generateQrData() async {
    // 1. Récupérer les données du kit
    final kit = await kitRepo.getKit();
  

    // 2. Récupérer les relays
    final relays = await relayRepo.getAllRelays();

    // 3. Récupérer les numéros autorisés
    final allowedUsers = await allowedRepo.getAllNumbers();

    // 4. Créer un objet complet
    final qrObject = {
      'kit': kit.map((k)=> k.toMap()).toList(),
      'relays': relays.map((r) => r.toMap()).toList(),
      'allowedUsers': allowedUsers.map((u) => u.toMap()).toList(),
    };

    // 5. Convertir en JSON
    return jsonEncode(qrObject);
  }

  /// Widget PrettyQr généré à partir du JSON
  Future<Widget> generateQrWidget({double size = 200}) async {
    final qrData = await generateQrData();
    return PrettyQr(
      data: qrData,
      size: size,
      roundEdges: true,
      typeNumber: 4,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
  }
}
