import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigService {
  static bool _adsEnabled = false;
  static bool get adsEnabled => _adsEnabled;

  /// Fetch remote config from Supabase once at app start, cached in memory.
  /// Toggle ads: UPDATE app_config SET value = 'true' WHERE key = 'ads_enabled';
  static Future<void> load() async {
    try {
      final data = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'ads_enabled')
          .maybeSingle();
      _adsEnabled = data?['value'] == 'true';
    } catch (e) {
      _adsEnabled = false; // fail-safe — never show ads if config unreachable
      debugPrint('[AppConfig] load error: $e');
    }
  }
}
