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

  Future<List<Map<String, dynamic>>> fetchAdoredPersonsByUserId(
    ObjectId userId,
  ) async {
    await connect();
    final collection = adoredPersons;
    if (collection == null) return const [];
    return collection
        .find(where.eq('userId', userId).sortBy('createdAt', descending: true))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchObservationLogsByPerson(
    ObjectId adoredPersonId,
  ) async {
    await connect();
    final collection = observationLogs;
    if (collection == null) return const [];
    return collection
        .find(where
            .eq('adoredPersonId', adoredPersonId)
            .sortBy('date', descending: true))
        .toList();
  }

  Future<Map<String, dynamic>?> fetchAdoredPersonById(ObjectId id) async {
    await connect();
    final collection = adoredPersons;
    if (collection == null) return null;
    return collection.findOne(where.id(id));
  }

  Future<Map<String, dynamic>?> createObservationLog({
    required ObjectId userId,
    required ObjectId adoredPersonId,
    required DateTime date,
    required String activity,
    required String thoughts,
    List<String> tags = const [],
  }) async {
    await connect();
    final collection = observationLogs;
    if (collection == null) return null;

    // Calculate streaks based on last observation date
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastObservationDate;

    final adored = await adoredPersons?.findOne(where.id(adoredPersonId));
    if (adored != null) {
      final stats = adored['stats'];
      if (stats is Map<String, dynamic>) {
        final rawCurrent = stats['currentStreak'];
        final rawLongest = stats['longestStreak'];
        currentStreak = rawCurrent is int
            ? rawCurrent
            : (rawCurrent is num ? rawCurrent.toInt() : 0);
        longestStreak = rawLongest is int
            ? rawLongest
            : (rawLongest is num ? rawLongest.toInt() : 0);

        final rawLast = stats['lastObservationDate'];
        if (rawLast is DateTime) {
          lastObservationDate = rawLast;
        } else if (rawLast is String) {
          lastObservationDate = DateTime.tryParse(rawLast);
        }
      }
    }

    final newDateOnly = DateTime(date.year, date.month, date.day);
    int updatedStreak;
    if (lastObservationDate == null) {
      updatedStreak = 1;
    } else {
      final lastDateOnly = DateTime(
        lastObservationDate.year,
        lastObservationDate.month,
        lastObservationDate.day,
      );
      final diffDays = newDateOnly.difference(lastDateOnly).inDays;
      if (diffDays == 1) {
        updatedStreak = currentStreak + 1;
      } else if (diffDays == 0) {
        // Same day entry keeps the current streak value.
        updatedStreak = currentStreak;
      } else {
        updatedStreak = 1;
      }
    }
    final updatedLongest = updatedStreak > longestStreak
        ? updatedStreak
        : longestStreak;

    final doc = <String, dynamic>{
      'userId': userId,
      'adoredPersonId': adoredPersonId,
      'date': date,
      'activity': activity,
      'thoughts': thoughts,
      'tags': tags,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    await collection.insertOne(doc);

    // update adored person stats basics
    await adoredPersons?.updateOne(
      where.id(adoredPersonId),
      modify
          .inc('stats.totalObservations', 1)
          .set('stats.currentStreak', updatedStreak)
          .set('stats.longestStreak', updatedLongest)
          .set('stats.lastObservationDate', date)
          .set('updatedAt', DateTime.now()),
      upsert: false,
    );

    return doc;
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

  Future<Map<String, dynamic>?> createAdoredPerson({
    required ObjectId userId,
    required String name,
    String? description,
    String? profileImage,
    List<Map<String, dynamic>> socialLinks = const [],
  }) async {
    await connect();
    final collection = adoredPersons;
    if (collection == null) return null;

    final now = DateTime.now();
    final doc = <String, dynamic>{
      'userId': userId,
      'name': name,
      'description': description,
      'profileImage': profileImage,
      'socialLinks': socialLinks,
      'stats': {
        'totalObservations': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastObservationDate': null,
      },
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
