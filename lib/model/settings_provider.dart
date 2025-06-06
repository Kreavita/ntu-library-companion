import 'package:flutter/material.dart';
import 'package:json_store/json_store.dart';
import 'package:ntu_library_companion/model/student.dart';

class SettingsProvider with ChangeNotifier {
  final Map<String, dynamic> _settings = {};
  JsonStore? _jsonStore;

  dynamic get(String key) => _settings[key];

  bool get loggedIn => get("credentials") != null;

  void set(String key, dynamic value) {
    if (!_settings.containsKey(key)) {
      throw StateError("$key not present in settings");
    }
    _settings[key] = value;
    _jsonStore?.setItem("settings", toJson());
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    final contactsJson =
        (_settings['contacts'] as Map<String, Student>).values
            .map((s) => s.toJson())
            .toList();
    return {
      ..._settings,
      'contacts': contactsJson,
      'accountHolder': _settings['accountHolder']?.toJson(),
    };
  }

  void loadJson({required Map<String, dynamic> jsonObj, JsonStore? jsonStore}) {
    final Map<String, Student> contacts = {};
    if (jsonObj['contacts'] != null) {
      for (var v in (jsonObj['contacts'] as List)) {
        final Student s = Student.fromJson(v);
        contacts[s.uuid] = s;
      }
    }

    _settings.addAll({
      'darkMode': jsonObj['darkMode'] ?? false,
      'notifications': jsonObj['notifications'] ?? false,
      // creds: {'user': '', 'pass': '', 'ntuSession': ''}
      'credentials': jsonObj['credentials'] ?? null as Map<String, String>?,
      'accountHolder':
          (jsonObj['accountHolder'] != null)
              ? Student.fromJson(jsonObj['accountHolder'])
              : null as Student?,
      'authToken': jsonObj['authToken'] ?? '',
      'authToken_date': jsonObj['authToken_date'] ?? '1970-01-01',
      'contacts': contacts,
    });
    _jsonStore = jsonStore;
    notifyListeners();
  }

  static final Map<String, dynamic> _cache = {};
  static get zh2engName => _cache["zh2engName"] ?? {};
  static get type2engName => _cache["type2engName"] ?? {};

  dynamic updateCache(String key, dynamic data) {
    _cache[key] = data;
    _jsonStore?.setItem("cache", _cache);
    notifyListeners();
  }

  void clearCache() {
    _cache.clear();
    _jsonStore?.setItem("cache", {});
    notifyListeners();
  }

  void loadCache({required Map<String, dynamic> jsonObj}) =>
      _cache.addAll(jsonObj);
}
