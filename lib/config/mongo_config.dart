// lib/config/mongo_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lazily fetches the MongoDB connection string from .env ensuring the value is
/// read only after [dotenv.load] completes.
String get mongoConnectionString =>
    dotenv.env['MONGO_CONNECTION_STRING'] ?? '';
