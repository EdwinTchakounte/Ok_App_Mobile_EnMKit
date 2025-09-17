import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/relay_model.dart';

class RelayRepository {
  final DBService _dbService;
  RelayRepository(this._dbService);

  // Ajouter un relais
  Future<void> addRelay(RelayModel relay) async {
    final db = await _dbService.database;
    await db.insert('relays', relay.toMap());
  }

  // Récupérer tous les relais
  Future<List<RelayModel>> getAllRelays() async {
    final db = await _dbService.database;
    final maps = await db.query('relays');
    return maps.map((m) => RelayModel.fromMap(m)).toList();
  }

  // Mettre à jour un relais complet
  Future<void> updateRelay(RelayModel relay) async {
    final db = await _dbService.database;
    await db.update(
      'relays',
      relay.toMap(),
      where: 'id = ?',
      whereArgs: [relay.id],
    );
  }

  // Modifier uniquement le nom du relais
  Future<void> updateRelayName(String id, String newName) async {
    final db = await _dbService.database;
    await db.update(
      'relays',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprimer un relais
  Future<void> deleteRelay(String id) async {
    final db = await _dbService.database;
    await db.delete(
      'relays',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

    /// Supprime tous les relais
  Future<void> clearRelays() async {
    final db = await _dbService.database;
    await db.delete('relays');
  }
}
