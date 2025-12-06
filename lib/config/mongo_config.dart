// lib/config/mongo_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default MongoDB connection string used by [MongoService]. Loaded from .env.
final String mongoConnectionString =
    dotenv.env['MONGO_CONNECTION_STRING'] ?? '';
