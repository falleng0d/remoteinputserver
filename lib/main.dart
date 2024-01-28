// ignore_for_file: avoid_print
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:remotecontrol/pages/server_starter.page.dart';
import 'package:remotecontrol/services/input_config.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:window_manager/window_manager.dart';

import 'services/win32_input_service.dart';
import 'theme.dart';

const String appTitle = 'Remote Input Server';

const double DEFAULT_WIDTH = 545;
const double DEFAULT_HEIGHT = 545;

/// Checks if the current environment is a desktop environment.
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  if ([TargetPlatform.windows, TargetPlatform.android].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor;
  }

  if (isDesktop) {
    await initWindow(prefs);
  }

  setPathUrlStrategy();

  logger.subscribe(Level.trace, (_, message) => print(message));

  await initDependencies(prefs);

  runApp(const MyApp());
}

Future<void> initWindow(SharedPreferences prefs) async {
  await flutter_acrylic.Window.initialize();

  await WindowManager.instance.ensureInitialized();

  windowManager.waitUntilReadyToShow().then((_) async {
    // Load position and size from prefs
    final width = prefs.getDouble('width') ?? DEFAULT_WIDTH;
    final height = prefs.getDouble('height') ?? DEFAULT_HEIGHT;

    final x = prefs.getDouble('x');
    final y = prefs.getDouble('y');
    if (x != null && y != null) await windowManager.setPosition(Offset(x, y));

    await windowManager.setSize(Size(width, height));
    await windowManager.setMinimumSize(const Size(DEFAULT_WIDTH, DEFAULT_HEIGHT));

    await windowManager.setPreventClose(true);
    await windowManager.show();
  });
}

Future<void> initDependencies(SharedPreferences prefs) async {
  // Provide the dependencies via GetX.
  final inputService = Win32InputService(logger);
  Get.put(inputService);

  final inputConfig = await KeyboardInputConfig(inputService, prefs).load();
  Get.put(inputConfig);

  Get.put(KeyboardInputService(inputService, inputConfig, logger));
}

final _appTheme = AppTheme();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appTheme,
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();

        return FluentApp(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          initialRoute: '/',
          routes: {'/': (_) => const MyHomePage(title: appTitle)},
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            // scaffoldBackgroundColor: Colors.white,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
            scaffoldBackgroundColor: Colors.white,
          ),
          builder: (context, child) {
            appTheme.setEffect(appTheme.windowEffect, context);
            return Directionality(
              textDirection: appTheme.textDirection,
              child: child!,
            );
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title = ""});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  bool value = false;
  int index = 0;
  late SharedPreferences prefs;

  final settingsController = ScrollController();

  @override
  void initState() {
    Future.sync(() async {
      prefs = await SharedPreferences.getInstance();
      windowManager.addListener(this);
    });

    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    settingsController.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();

    // ignore: use_build_context_synchronously
    if (!context.mounted) return;

    if (isPreventClose) {
      await showDialog(
        context: context,
        builder: (_) {
          return ContentDialog(
            title: const Text('Confirm close'),
            content: const Text('Are you sure you want to close this window?'),
            actions: [
              FilledButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(context);
                  windowManager.destroy();
                },
              ),
              Button(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void onWindowMoved() {
    WindowManager.instance.getPosition().then((value) {
      prefs.setDouble('x', value.dx);
      prefs.setDouble('y', value.dy);
    });
  }

  @override
  void onWindowResized() {
    WindowManager.instance.getSize().then((value) {
      prefs.setDouble('width', value.width);
      prefs.setDouble('height', value.height);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ServerPage();
  }
}
