import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
  }

  static String get supabaseUrl => _readEnv('SUPABASE_URL');
  static String get supabaseAnonKey => _readEnv('SUPABASE_ANON_KEY');

  static String _readEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in environment configuration.');
    }
    return value;
  }
}
