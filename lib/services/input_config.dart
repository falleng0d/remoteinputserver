import 'package:get/get.dart';
import 'package:remotecontrol/services/win32_input_service.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeyboardInputConfig extends GetxService {
  final Win32InputService _inputService;
  final SharedPreferences _prefs;
  bool _initialized = false;

  final _cursorSpeed = 1.0.obs;
  final _cursorAcceleration = 1.0.obs;
  int _keyPressInterval = 33;

  // 1s
  Duration keyRepeatDelay = const Duration(milliseconds: 300);
  // 15hz
  Duration keyRepeatInterval = const Duration(milliseconds: 1000 ~/ 30);

  get cursorSpeed => _cursorSpeed.value;
  get cursorAcceleration => _cursorAcceleration.value;
  int get keyPressInterval => _keyPressInterval;

  RxInt updateNotifier = RxInt(0);

  final _isDebug = false.obs;

  bool get isDebug => _isDebug.value;

  KeyboardInputConfig(this._inputService, this._prefs);

  /// Loads the configuration from the shared preferences.
  /// Must be called before using the configuration.
  Future<KeyboardInputConfig> load() async {
    _initialized = true;
    setCursorSpeed(_prefs.getDouble('cursorSpeed') ?? cursorSpeed);
    setCursorAcceleration(_prefs.getDouble('cursorAcceleration') ?? cursorAcceleration);
    setDebug(_prefs.getBool('debug') ?? isDebug);
    _keyPressInterval = _prefs.getInt('keyPressInterval') ?? keyPressInterval;
    return this;
  }

  void notify() {
    updateNotifier.value++;
  }

  Future<bool> setCursorSpeed(double speed) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    if (speed < 0) {
      logger.error("Speed must be greater than 0");
      return false;
    }
    if (speed > 2) {
      logger.error("Speed must be less than 2");
      return false;
    }
    if (await _prefs.setDouble('cursorSpeed', speed)) {
      _cursorSpeed.value = speed;
      notify();

      return true;
    }

    return false;
  }

  Future<bool> setCursorAcceleration(double acceleration) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    if (acceleration < 0) {
      logger.error("Acceleration must be greater than 0");
      return false;
    }
    if (acceleration > 2) {
      logger.error("Acceleration must be less than 2");
      return false;
    }
    if (await _prefs.setDouble('cursorAcceleration', acceleration)) {
      _cursorAcceleration.value = acceleration;
      notify();

      return true;
    }

    return false;
  }

  Future<bool> setKeyPressInterval(int interval) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    if (await _prefs.setInt('keyPressInterval', interval)) {
      _keyPressInterval = interval;
      notify();

      return true;
    }

    return false;
  }

  Future<bool> setDebug(bool debug) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    if (await _prefs.setBool('debug', debug)) {
      _isDebug.value = debug;
      _inputService.isDebug = debug;
      notify();

      return true;
    }

    return false;
  }
}
