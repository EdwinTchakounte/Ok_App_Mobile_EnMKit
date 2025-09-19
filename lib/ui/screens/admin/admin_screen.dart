import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/core/sms_service.dart';
import 'package:enmkit/repositories/relay_repository.dart';
import 'package:enmkit/repositories/kit_repository.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final TextEditingController _newRelayNameController = TextEditingController();
  final TextEditingController _newAmperageController = TextEditingController();
  final TextEditingController _pulsationController = TextEditingController();
  final TextEditingController _consumptionController = TextEditingController();
  final TextEditingController _editRelayNameController = TextEditingController();
  final TextEditingController _editAmperageController = TextEditingController();
  
  bool _isLoading = false;
  List<RelayModel> _relays = [];
  KitModel? _kitConfig;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _newRelayNameController.dispose();
    _newAmperageController.dispose();
    _pulsationController.dispose();
    _consumptionController.dispose();
    _editRelayNameController.dispose();
    _editAmperageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final relayRepo = RelayRepository(ref.read(dbServiceProvider));
      final kitRepo = KitRepository(ref.read(dbServiceProvider));
      
      _relays = await relayRepo.getAllRelays();
      final kits = await kitRepo.getKit();
      _kitConfig = kits.isNotEmpty ? kits.first : null;
      
      if (_kitConfig != null) {
        _pulsationController.text = _kitConfig!.pulseCount?.toString() ?? '';
        _consumptionController.text = _kitConfig!.initialConsumption?.toString() ?? '';
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRelay() async {
    if (_newRelayNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir un nom pour le relais');
      return;
    }

    final amperage = int.tryParse(_newAmperageController.text.trim());
    if (amperage == null || amperage <= 0) {
      _showErrorSnackBar('Veuillez saisir un ampérage valide (> 0)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final relayRepo = RelayRepository(ref.read(dbServiceProvider));
      final newRelay = RelayModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _newRelayNameController.text.trim(),
        amperage: amperage,
      );
      
      await relayRepo.addRelay(newRelay);
      _newRelayNameController.clear();
      _newAmperageController.clear();
      await _loadData();
      // Invalider la lecture DB pour rafraîchir l'UI utilisateur
      ref.invalidate(dbRelaysProvider);
      _showSuccessSnackBar('Relais ajouté avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'ajout du relais: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editRelay(RelayModel relay) async {
    _editRelayNameController.text = relay.name ?? '';
    _editAmperageController.text = relay.amperage.toString();

    final result = await showDialog<RelayModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le relais'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editRelayNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du relais',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _editAmperageController,
              decoration: const InputDecoration(
                labelText: 'Ampérage (A)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final newName = _editRelayNameController.text.trim();
              final newAmp = int.tryParse(_editAmperageController.text.trim());
              if (newName.isEmpty || newAmp == null || newAmp <= 0) {
                return;
              }
              Navigator.of(context).pop(
                RelayModel(
                  id: relay.id,
                  name: newName,
                  amperage: newAmp,
                  isActive: relay.isActive,
                ),
              );
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final relayRepo = RelayRepository(ref.read(dbServiceProvider));
        await relayRepo.updateRelay(result);
        await _loadData();
        ref.invalidate(dbRelaysProvider);
        _showSuccessSnackBar('Relais modifié avec succès');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la modification: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveKitConfiguration() async {
    if (_pulsationController.text.trim().isEmpty || _consumptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs');
      return;
    }

    final pulsation = int.tryParse(_pulsationController.text.trim());
    final consumption = double.tryParse(_consumptionController.text.trim());

    if (pulsation == null || consumption == null) {
      _showErrorSnackBar('Veuillez saisir des valeurs numériques valides');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final kitRepo = KitRepository(ref.read(dbServiceProvider));
      final smsService = SmsService(kitRepo);
      
      // Créer ou mettre à jour la configuration du kit
      final kitConfig = KitModel(
        kitNumber: _kitConfig?.kitNumber ?? '0000000000', // Numéro par défaut si pas de kit
        initialConsumption: consumption,
        pulseCount: pulsation,
      );

      if (_kitConfig == null) {
        await kitRepo.addKit(kitConfig);
      } else {
        await kitRepo.updateKit(kitConfig);
      }

      // Envoyer les paramètres par SMS
      await smsService.setPulsation(pulsation);
      await smsService.setInitialConsumption(consumption.toInt());

      await _loadData();
      _showSuccessSnackBar('Configuration sauvegardée et envoyée au kit');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Configuration Kit
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuration du Kit',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pulsationController,
                            decoration: const InputDecoration(
                              labelText: 'Pulsation',
                              hintText: 'Nombre de pulsations par kWh',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.speed),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _consumptionController,
                            decoration: const InputDecoration(
                              labelText: 'Consommation Initiale (kWh)',
                              hintText: 'Valeur de consommation de départ',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.electrical_services),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saveKitConfiguration,
                              icon: const Icon(Icons.send),
                              label: const Text('Sauvegarder et Envoyer au Kit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Section Gestion des Relais
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gestion des Relais',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: _addRelay,
                                icon: const Icon(Icons.add),
                                tooltip: 'Ajouter un relais',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Formulaire d'ajout de relais
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newRelayNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nom du nouveau relais',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _newAmperageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Amp (A)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addRelay,
                                child: const Text('Ajouter'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Liste des relais
                          if (_relays.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('Aucun relais configuré'),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _relays.length,
                              itemBuilder: (context, index) {
                                final relay = _relays[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: relay.isActive ? Colors.green : Colors.grey,
                                      child: Icon(
                                        Icons.power,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(relay.name ?? 'Relais ${index + 1}'),
                                    subtitle: Text('Ampérage: ${relay.amperage}A'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _editRelay(relay),
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Modifier',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
