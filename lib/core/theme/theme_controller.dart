import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import '../utils/safe_change_notifier.dart';

class ThemeController extends SafeChangeNotifier {
  ThemeController(this._settingsRepository);

  final SettingsRepository _settingsRepository;
  AppSettings _settings = AppSettings.defaults();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get loaded => _loaded;

  Future<void> load() async {
    _settings = await _settingsRepository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(SleewaveThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _settingsRepository.save(_settings);
    notifyListeners();
  }

  Future<void> setGlowMode(GlowMode mode) async {
    _settings = _settings.copyWith(glowMode: mode);
    await _settingsRepository.save(_settings);
    notifyListeners();
  }

  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    await _settingsRepository.save(settings);
    notifyListeners();
  }
}
