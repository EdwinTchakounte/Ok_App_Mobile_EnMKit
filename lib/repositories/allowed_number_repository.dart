import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/allowed_number_model.dart';

class AllowedNumberRepository {
  final DBService _dbService;
  AllowedNumberRepository(this._dbService);

  // Ajouter un numéro
  Future<void> addNumber(AllowedNumberModel number) async {
    final db = await _dbService.database;
    await db.insert('allowed_numbers', number.toMap());
  }

  // Récupérer tous les numéros
  Future<List<AllowedNumberModel>> getAllNumbers() async {
    final db = await _dbService.database;
    final maps = await db.query('allowed_numbers');
    return maps.map((m) => AllowedNumberModel.fromMap(m)).toList();
  }

  // Mettre à jour un numéro
  Future<void> updateNumber(AllowedNumberModel number) async {
    final db = await _dbService.database;
    await db.update(
      'allowed_numbers',
      number.toMap(),
      where: 'id = ?',
      whereArgs: [number.id],
    );
  }

  // Supprimer un numéro
  Future<void> deleteNumber(int id) async {
    final db = await _dbService.database;
    await db.delete(
      'allowed_numbers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

    /// Supprime tous les numéros autorisés
  Future<void> clearAllowedNumbers() async {
    final db = await _dbService.database;
    await db.delete('allowed_numbers');
  }

  Future<void> replaceAll(List<dynamic> numbersMaps) async {
    final db = await _dbService.database;
    final batch = db.batch();
    batch.delete('allowed_numbers');
    for (final m in numbersMaps) {
      batch.insert('allowed_numbers', m as Map<String, dynamic>);
    }
    await batch.commit(noResult: true);
  }
}
