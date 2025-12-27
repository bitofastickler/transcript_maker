import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static const _supabaseUrlDefine =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const _supabaseAnonKeyDefine =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get _hasDartDefines =>
      _supabaseUrlDefine.isNotEmpty && _supabaseAnonKeyDefine.isNotEmpty;

  static Future<void> load({String fileName = '.env'}) async {
    if (_hasDartDefines) {
      return;
    }
    await dotenv.load(fileName: fileName);
  }

  static String get supabaseUrl =>
      _hasDartDefines ? _supabaseUrlDefine : _readEnv('SUPABASE_URL');
  static String get supabaseAnonKey =>
      _hasDartDefines ? _supabaseAnonKeyDefine : _readEnv('SUPABASE_ANON_KEY');

  static String _readEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in environment configuration.');
    }
    return value;
  }
}
