import 'package:get/get.dart';
import 'package:remotecontrol/services/win32_input_service.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeyboardInputConfig extends GetxService {
  final Win32InputService _inputService;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _initialized = false;

  double _cursorSpeed = 1.0;
  double _cursorAcceleration = 1.0;
  int _keyPressInterval = 50;

  // 1s
  Duration keyRepeatDelay = const Duration(milliseconds: 300);
  // 15hz
  Duration keyRepeatInterval = const Duration(milliseconds: 1000 ~/ 15);

  double get cursorSpeed => _cursorSpeed;
  double get cursorAcceleration => _cursorAcceleration;
  int get keyPressInterval => _keyPressInterval;

  RxInt updateNotifier = RxInt(0);

  final _isDebug = false.obs;
  set isDebug(bool value) {
    _isDebug.value = value;
    _inputService.isDebug = value;
  }

  bool get isDebug => _isDebug.value;

  KeyboardInputConfig(this._inputService);

  /// Loads the configuration from the shared preferences.
  /// Must be called before using the configuration.
  Future<KeyboardInputConfig> load() async {
    final prefs = await _prefs;
    _initialized = true;
    setCursorSpeed(prefs.getDouble('cursorSpeed') ?? cursorSpeed);
    setCursorAcceleration(prefs.getDouble('cursorAcceleration') ?? cursorAcceleration);
    _keyPressInterval = prefs.getInt('keyPressInterval') ?? keyPressInterval;
    return this;
  }

  void notify() {
    updateNotifier.value++;
  }

  Future<bool> setCursorSpeed(double speed) async {
    if (!(_initialized)) throw Exception('_prefs not initialized!');
    final prefs = await _prefs;
    if (speed < 0) {
      logger.error("Speed must be greater than 0");
      return false;
    }
    if (speed > 2) {
      logger.error("Speed must be less than 2");
      return false;
    }
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
    if (acceleration < 0) {
      logger.error("Acceleration must be greater than 0");
      return false;
    }
    if (acceleration > 2) {
      logger.error("Acceleration must be less than 2");
      return false;
    }
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
