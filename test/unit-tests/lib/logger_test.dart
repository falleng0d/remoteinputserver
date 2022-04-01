import 'package:flutter_test/flutter_test.dart';
import 'package:remotecontrol/logger.dart';

void main() {
  test('Logger should invoke subscribed callbacks', () {
    final logger = Logger();
    logger.subscribe(Level.debug, (level, message) {
      expect(level, Level.debug);
      expect(message.contains('test'), true);
      expect(message.contains('[debug]'), true);
    });
    logger.debug('test');
  });

  test('Logger should invoke subscribed callbacks with custom level', () {
    final logger = Logger();
    logger.subscribe(Level.info, (level, message) {
      expect(level, Level.info);
      expect(message.contains('test'), true);
      expect(message.contains('[info]'), true);
    });
    logger.info('test');
  });

  test('Logger should invoke subscribed callbacks with higher level', () {
    final logger = Logger();
    logger.subscribe(Level.debug, (level, message) {
      expect(level, Level.info);
      expect(message.contains('test'), true);
      expect(message.contains('[info]'), true);
    });
    logger.info('test');
  });

  test('Logger should not invoke subscribed callbacks with lower level', () {
    final logger = Logger();
    logger.subscribe(Level.error, (level, message) {
      fail('Should not be called');
    });
    logger.info('test');
  });

  test('Logger should not crash when there are no subscribers', () {
    final logger = Logger();
    logger.debug('test');
  });
}
