import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/repositories/relay_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de la liste des relais
class RelayListState {
  final bool isLoading;
  final List<RelayModel> relays;
  final String? error;

  RelayListState({
    this.isLoading = false,
    this.relays = const [],
    this.error,
  });

  /// Copie avec de nouveaux paramètres
  RelayListState copyWith({
    bool? isLoading,
    List<RelayModel>? relays,
    String? error,
  }) {
    return RelayListState(
      isLoading: isLoading ?? this.isLoading,
      relays: relays ?? this.relays,
      error: error,
    );
  }
}

/// ViewModel pour la liste des relais
class RelayListVM extends StateNotifier<RelayListState> {
  final RelayRepository _relayRepository;

  RelayListVM(this._relayRepository) : super(RelayListState());

  /// Charger tous les relais
  Future<void> loadRelays() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final relays = await _relayRepository.getAllRelays();
      state = state.copyWith(
        isLoading: false,
        relays: relays,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des relais: ${e.toString()}',
      );
    }
  }

  /// Actualiser la liste des relais
  Future<void> refreshRelays() async {
    await loadRelays();
  }

  /// Mettre à jour l'état d'un relais
  Future<void> toggleRelayState(RelayModel relay) async {
    try {
      final updatedRelay = RelayModel(
        id: relay.id,
        name: relay.name,
        isActive: !relay.isActive,
        amperage: relay.amperage,
      );
      
      await _relayRepository.updateRelay(updatedRelay);
      
      // Mettre à jour la liste locale
      final updatedRelays = state.relays.map((r) {
        if (r.id == relay.id) {
          return updatedRelay;
        }
        return r;
      }).toList();
      
      state = state.copyWith(relays: updatedRelays);
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de la mise à jour du relais: ${e.toString()}',
      );
    }
  }

  /// Mettre à jour le nom d'un relais
  Future<void> updateRelayName(String relayId, String newName) async {
    try {
      await _relayRepository.updateRelayName(relayId, newName);
      
      // Mettre à jour la liste locale
      final updatedRelays = state.relays.map((r) {
        if (r.id == relayId) {
          return RelayModel(
            id: r.id,
            name: newName,
            isActive: r.isActive,
            amperage: r.amperage,
          );
        }
        return r;
      }).toList();
      
      state = state.copyWith(relays: updatedRelays);
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de la mise à jour du nom: ${e.toString()}',
      );
    }
  }

  /// Supprimer un relais
  Future<void> deleteRelay(String relayId) async {
    try {
      await _relayRepository.deleteRelay(relayId);
      
      // Mettre à jour la liste locale
      final updatedRelays = state.relays.where((r) => r.id != relayId).toList();
      state = state.copyWith(relays: updatedRelays);
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de la suppression du relais: ${e.toString()}',
      );
    }
  }

  /// Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}
