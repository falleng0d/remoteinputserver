import 'package:intl/intl.dart';

enum Level { error, info, warning, debug, trace }

class LoggerSettings {
  Level level;
  DateFormat dateFormat;

  /// Tha available [logFormat] variables are:
  /// %level%, %date%, %message%
  String logFormat;

  LoggerSettings(
      {required this.level, required this.dateFormat, required this.logFormat});
}

class Logger {
  LoggerSettings settings = LoggerSettings(
    level: Level.debug,
    dateFormat: DateFormat(DateFormat.HOUR24_MINUTE_SECOND),
    logFormat: '[%level%] %date%: %message%',
  );

  static final Logger _globalInstance = Logger();

  /// The global instance of the logger.
  factory Logger.instance() {
    return _globalInstance;
  }

  final Map<Level, List<void Function(Level, String)>> _listeners = {
    Level.error: [],
    Level.info: [],
    Level.warning: [],
    Level.debug: [],
    Level.trace: [],
  };

  Logger({LoggerSettings? settings}) {
    if (settings != null) {
      this.settings = settings;
    }
  }

  Level get level => settings.level;

  subscribe(Level level, void Function(Level, String) callback) {
    _listeners[level]?.add(callback);
  }

  unsubscribe(Level level, void Function(Level, String) callback) {
    _listeners[level]?.remove(callback);
  }

  _dispatch(Level level, String message) {
    for (final listener in _listeners[level]!) {
      listener(level, message);
    }
  }

  _format(String message, Level level) {
    final date = settings.dateFormat.format(DateTime.now());
    final formattedMessage = settings.logFormat
        .replaceAll('%level%', level.name)
        .replaceAll('%date%', date)
        .replaceAll('%message%', message);
    return formattedMessage;
  }

  log(String message, {Level? level}) {
    if (level != null && level.index < this.level.index) {
      return;
    }

    var messageLogLevel = level ?? this.level;
    final formattedMessage = _format(message, messageLogLevel);
    _dispatch(messageLogLevel, formattedMessage);
  }

  debug(String message) => log(message, level: Level.debug);

  info(String message) => log(message, level: Level.info);

  warning(String message) => log(message, level: Level.warning);

  error(String message) => log(message, level: Level.error);

  trace(String message) => log(message, level: Level.trace);
}
