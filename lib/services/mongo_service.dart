// lib/services/mongo_service.dart
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../config/mongo_config.dart';

/// Handles direct MongoDB access from Flutter.
class MongoService {
  Db? _db;
  DbCollection? users;
  DbCollection? adoredPersons;
  DbCollection? observationLogs;

  /// Opens a single shared connection and caches frequently used collections.
  Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;
    final connection = mongoConnectionString;
    if (connection.isEmpty) {
      throw StateError('MONGO_CONNECTION_STRING is missing.');
    }
    try {
      final db = await Db.create(connection);
      await db.open();
      _db = db;
      users = db.collection('users');
      adoredPersons = db.collection('adoredPersons');
      observationLogs = db.collection('observationLogs');
    } catch (e, stack) {
      debugPrint('Mongo connection failed: $e\n$stack');
      rethrow;
    }
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

  /// Returns the user document for [email] if it exists.
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    await connect();
    final collection = users;
    if (collection == null) return null;
    return collection.findOne({'email': email});
  }

  /// Simple email+password login. Returns user map if credentials match.
  Future<Map<String, dynamic>?> loginWithEmail(
    String email,
    String password,
  ) async {
    final user = await findUserByEmail(email);
    if (user == null) return null;
    return user['password'] == password ? user : null;
  }

  /// Creates a new user if the email is not already taken.
  Future<Map<String, dynamic>?> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    await connect();
    final collection = users;
    if (collection == null) return null;

    final existing = await collection.findOne({'email': email});
    if (existing != null) {
      return null;
    }

    final now = DateTime.now();
    final doc = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'createdAt': now,
      'updatedAt': now,
    };

    await collection.insertOne(doc);
    return doc;
  }
}

/// Global singleton-like instance any widget can call to reuse the same Db
/// session.
final MongoService mongoService = MongoService();
