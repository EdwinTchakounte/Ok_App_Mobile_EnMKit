import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/kit_model.dart';

class KitRepository {
  final DBService _dbService;
  KitRepository(this._dbService);

  Future<void> addKit(KitModel kit) async {
    final db = await _dbService.database;
    await db.insert('kits', kit.toMap());
  }

  Future<List<KitModel>> getKit() async {
    final db = await _dbService.database;
    final kitMaps = await db.query('kits'); // SQLite natif
    return kitMaps.map((map) => KitModel.fromMap(map)).toList();
  }

  Future<void> updateKit(KitModel kit) async {
    final db = await _dbService.database;
    await db.update(
      'kits',
      kit.toMap(),
      where: 'kitNumber = ?',
      whereArgs: [kit.kitNumber],
    );
  }

  Future<void> deleteKit(String kitNumber) async {
    final db = await _dbService.database;
    await db.delete(
      'kits',
      where: 'kitNumber = ?',
      whereArgs: [kitNumber],
    );
  }
}
