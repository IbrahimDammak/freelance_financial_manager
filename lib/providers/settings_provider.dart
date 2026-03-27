import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._settingsBox) {
    _settings = _settingsBox.get('app') as AppSettings? ?? AppSettings();
    _settingsBox.put('app', _settings);
  }

  final Box _settingsBox;
  late AppSettings _settings;

  AppSettings get settings => _settings;

  Future<void> updateHourlyRate(double rate) async {
    if (rate.isNaN || rate.isInfinite || rate < 0) return;
    _settings.hourlyRate = rate;
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    if (!AppSettings.supportedCurrencies.contains(currency)) return;
    _settings.currency = currency;
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }
}
