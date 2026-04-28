import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get orsApiKey {
    final key = dotenv.maybeGet('ORS_API_KEY');
    if (key == null || key.isEmpty || key == 'your-ors-key-here') {
      throw StateError('ORS_API_KEY missing in .env');
    }
    return key;
  }
}
