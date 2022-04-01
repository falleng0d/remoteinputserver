import 'dart:ffi';

import 'package:intl/intl.dart';


enum Level {
  error,
  info,
  warning,
  debug,
  trace
}

class LoggerSettings {
  Level level;
  DateFormat dateFormat;

  LoggerSettings({required this.level, required this.dateFormat});
}

class Logger {
  LoggerSettings settings = LoggerSettings(level: Level.debug,
      dateFormat: DateFormat(DateFormat.HOUR24_MINUTE_SECOND));

  List<void Function()> _listeners = [];

  Logger(LoggerSettings settings) {
    this.settings = settings;
  }

  Level get level => settings.level;

  subscribe(void Function() callback) {
    _listeners.add(callback);
  }

  log(String message, Level? level) {
    if (level != null) {
      if (level.index >= this.level.index) {
        print(message)
      }
    }
  }
}
