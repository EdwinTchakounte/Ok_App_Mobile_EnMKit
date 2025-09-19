import 'package:enmkit/core/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/repositories/relay_repository.dart';


class RelayViewModel extends ChangeNotifier {
  final RelayRepository _repository;
  final SmsService _smsService;

  // Liste des relais
  List<RelayModel> _relays = [];
  List<RelayModel> get relays => _relays;

  // Indicateur de chargement
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  RelayViewModel(DBService dbService, SmsService smsService)
      : _repository = RelayRepository(dbService),
        _smsService = smsService {
    fetchRelays();
  }

  /// Charger tous les relais depuis la base de données
  Future<void> fetchRelays() async {
    _isLoading = true;
    notifyListeners();

    _relays = await _repository.getAllRelays();

    _isLoading = false;
    notifyListeners();
  }

  /// Ajouter un nouveau relais
  Future<void> addRelay(RelayModel relay) async {
    await _repository.addRelay(relay);
    _relays.add(relay);
    notifyListeners();
  }

  /// Mettre à jour un relais complet
  Future<void> updateRelay(RelayModel relay) async {
    await _repository.updateRelay(relay);
    final index = _relays.indexWhere((r) => r.id == relay.id);
    if (index != -1) {
      _relays[index] = relay;
      notifyListeners();
    }
  }

  /// Toggle relais (mise à jour DB + envoi SMS)
  Future<void> toggleRelay(RelayModel relay) async {
    if (relay.id == null) {print("ttttttttttttttttttttttttttttttttt");return;}

    // Changer l'état localement
    relay.isActive = !relay.isActive;

    // 1️⃣ Mettre à jour la DB
    await _repository.updateRelay(relay);

    // 2️⃣ Envoyer le SMS correspondant
    final command = relay.isActive ? "r${relay.id}on" : "r${relay.id}off";
    try {
      await _smsService.toggleRelay(relay); // la méthode _sendCommand est utilisée à l'intérieur
    } catch (e) {
      // Si échec du SMS, on peut revenir à l'état précédent
      relay.isActive = !relay.isActive;
      await _repository.updateRelay(relay);
      notifyListeners();
      rethrow; // pour gestion côté UI
    }

    notifyListeners();
  }

  /// Supprimer un relais
  Future<void> deleteRelay(int id) async {
    await _repository.deleteRelay(id);
    _relays.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// Supprimer tous les relais
  Future<void> clearRelays() async {
    await _repository.clearRelays();
    _relays.clear();
    notifyListeners();
  }

  /// Mettre à jour uniquement le nom du relais
  Future<void> updateRelayName(String id, String newName) async {
    await _repository.updateRelayName(id, newName);
    final index = _relays.indexWhere((r) => r.id == id);
    if (index != -1) {
      _relays[index].name = newName;
      notifyListeners();
    }
  }

  int get activeRelaysCount {
    return _relays.where((r) => r.isActive).length;
  }

  /// Retourne le nombre de relais inactifs
  int get inactiveRelaysCount {
    return _relays.where((r) => !r.isActive).length;
  }
}
