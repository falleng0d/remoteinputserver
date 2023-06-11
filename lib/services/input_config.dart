import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InputConfig extends GetxService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _initialized = false;

  double _cursorSpeed = 1.0;
  double _cursorAcceleration = 1.0;
  int _keyPressInterval = 50;

  double get cursorSpeed => _cursorSpeed;
  double get cursorAcceleration => _cursorAcceleration;
  int get keyPressInterval => _keyPressInterval;

  RxInt updateNotifier = RxInt(0);

  final _isDebug = false.obs;
  set isDebug(bool value) => _isDebug.value = value;
  bool get isDebug => _isDebug.value;

  InputConfig();

  /// Loads the configuration from the shared preferences.
  /// Must be called before using the configuration.
  Future<InputConfig> load() async {
    final prefs = await _prefs;
    _cursorSpeed = prefs.getDouble('cursorSpeed') ?? cursorSpeed;
    _cursorAcceleration = prefs.getDouble('cursorAcceleration') ?? cursorAcceleration;
    _keyPressInterval = prefs.getInt('keyPressInterval') ?? keyPressInterval;
    _initialized = true;
    return this;
  }

  void notify() {
    updateNotifier.value++;
  }

  Future<bool> setCursorSpeed(double speed) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    final prefs = await _prefs;
    if (await prefs.setDouble('cursorSpeed', speed)) {
      _cursorSpeed = speed;
      notify();

      return true;
    }

    return false;
  }

  Future<bool> setCursorAcceleration(double acceleration) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    final prefs = await _prefs;
    if (await prefs.setDouble('cursorAcceleration', acceleration)) {
      _cursorAcceleration = acceleration;
      notify();

      return true;
    }

    return false;
  }

  Future<bool> setKeyPressInterval(int interval) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    final prefs = await _prefs;
    if (await prefs.setInt('keyPressInterval', interval)) {
      _keyPressInterval = interval;
      notify();

      return true;
    }

    return false;
  }
}
