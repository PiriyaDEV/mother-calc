import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// LocaleProvider — manages app language.
/// The locale is persisted in the `profiles.locale` column in Supabase.
/// On first load (before auth), defaults to 'th'.
/// Call [initFromProfile] after the profile is loaded to sync from DB.
/// Call [setLocale] to change language — it notifies listeners immediately
/// and the caller is responsible for persisting to DB (via UserStatsProvider).
class LocaleProvider extends ChangeNotifier {
  String _locale = 'th'; // 'th' | 'en'
  Map<String, String> _strings = {};

  String get locale => _locale;
  bool get isThai => _locale == 'th';

  LocaleProvider() {
    _loadStrings();
  }

  /// Called by AuthProvider after profile is loaded from Supabase.
  Future<void> initFromProfile(String profileLocale) async {
    if (_locale == profileLocale) return;
    _locale = profileLocale;
    await _loadStrings();
    notifyListeners();
  }

  Future<void> _loadStrings() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/i18n/$_locale.json');
      final Map<String, dynamic> raw = jsonDecode(jsonStr);
      _strings = raw.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      debugPrint('LocaleProvider: failed to load $_locale.json — $e');
      _strings = {};
    }
  }

  /// Translate a key. Falls back to the key itself if not found.
  String t(String key, {Map<String, String>? args}) {
    String val = _strings[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        val = val.replaceAll('{$k}', v);
      });
    }
    return val;
  }

  /// Change locale in-memory and reload strings.
  /// Caller must persist to DB via UserStatsProvider.saveLocale().
  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _loadStrings();
    notifyListeners();
  }

  void toggleLocale() {
    setLocale(_locale == 'th' ? 'en' : 'th');
  }
}
