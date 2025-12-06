// lib/services/mongo_service.dart
import 'package:mongo_dart/mongo_dart.dart';

import '../config/mongo_config.dart';

/// Handles direct MongoDB access from Flutter.
class MongoService {
  MongoService(String connectionString) : _connectionString = connectionString;

  final String _connectionString;
  Db? _db;
  DbCollection? users;
  DbCollection? adoredPersons;
  DbCollection? observationLogs;

  /// Opens a single shared connection and caches frequently used collections.
  Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;
    final db = await Db.create(_connectionString);
    await db.open();
    _db = db;
    users = db.collection('users');
    adoredPersons = db.collection('adoredPersons');
    observationLogs = db.collection('observationLogs');
  }

  /// Closes the database connection. Call this from `dispose` or `onTerminate`.
  Future<void> close() async {
    if (_db == null) return;
    await _db!.close();
    _db = null;
  }

  /// Example: fetch all adored persons for the given user id string.
  Future<List<Map<String, dynamic>>> fetchAdoredPersons(String userId) async {
    await connect();
    final collection = adoredPersons;
    if (collection == null) return const [];
    return collection
        .find({'userId': ObjectId.parse(userId)})
        .toList();
  }

  /// Example: insert a raw observation log map.
  Future<void> insertObservationLog(Map<String, dynamic> log) async {
    await connect();
    final collection = observationLogs;
    if (collection == null) return;
    await collection.insertOne(log);
  }
}

/// Global singleton-like instance using the default connection string so any
/// widget can call `mongoService.connect()` and reuse the same Db session.
final MongoService mongoService = MongoService(mongoConnectionString);
