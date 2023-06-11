// ignore_for_file: avoid_print
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:remotecontrol/pages/server_starter.page.dart';
import 'package:remotecontrol_lib/logger.dart';
import 'package:system_theme/system_theme.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:window_manager/window_manager.dart';

import 'services/win32_input_service.dart';
import 'theme.dart';

const String appTitle = 'Remote Input Server';

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

  if (kIsWeb ||
      [TargetPlatform.windows, TargetPlatform.android].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor;
  }

  setPathUrlStrategy();

  // Initialize the logger.
  logger.subscribe(Level.trace, (_, message) => print(message));

  // Provide the dependencies via GetX.
  Get.put(await InputConfig().load());

  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
          windowButtonVisibility: false);
      await windowManager.setSize(const Size(545, 545));
      await windowManager.setMinimumSize(const Size(545, 545));
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
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
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          builder: (context, child) {
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
  const MyHomePage({Key? key, this.title = ""}) : super(key: key);

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

  final settingsController = ScrollController();

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();

    /*Timer mytimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      logger.trace('Timer tick');
    });*/
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    return NavigationView(
      appBar: NavigationAppBar(
        title: () {
          if (kIsWeb) return const Text(appTitle);
          return const DragToMoveArea(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(appTitle),
            ),
          );
        }(),
        actions: kIsWeb
            ? null
            : DragToMoveArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 45,
                          height: 30,
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              IconButton(
                                  icon: const Icon(
                                    FluentIcons.chrome_minimize,
                                    color: Color.fromARGB(255, 154, 154, 154),
                                  ),
                                  onPressed: () {
                                    WindowManager.instance.minimize();
                                  }),
                            ],
                          ),
                        ),
                        Container(
                          width: 45,
                          height: 30,
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              IconButton(
                                  icon: const Icon(
                                    FluentIcons.chrome_close,
                                    color: Color.fromARGB(255, 154, 154, 154),
                                  ),
                                  onPressed: () {
                                    WindowManager.instance.setPreventClose(false);
                                    WindowManager.instance.close();
                                  }),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
      ),
      pane: NavigationPane(
        selected: index,
        onChanged: (i) => setState(() => index = i),
        size: const NavigationPaneSize(
          openMinWidth: 100,
          openMaxWidth: 320,
        ),
        header: Container(
          height: kOneLineTileHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: const FlutterLogo(
            style: FlutterLogoStyle.horizontal,
            size: 100,
          ),
        ),
        displayMode: appTheme.displayMode,
        indicator: () {
          switch (appTheme.indicator) {
            case NavigationIndicators.end:
              return const EndNavigationIndicator();
            case NavigationIndicators.sticky:
            default:
              return const StickyNavigationIndicator();
          }
        }(),
        items: [
          // It doesn't look good when resizing from compact to open
          // PaneItemHeader(header: Text('User Interaction')),
          PaneItem(
            icon: const Icon(FluentIcons.analytics_view),
            title: const Text('Server'),
            body: const ServerPage(),
          ),
        ],
        autoSuggestBox: AutoSuggestBox(
          controller: TextEditingController(),
          items: [
            AutoSuggestBoxItem(
              label: 'server',
              value: 'Server',
            ),
          ],
        ),
        autoSuggestBoxReplacement: const Icon(FluentIcons.search),
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: const Text('Settings Page'),
          ),
        ],
      ),
    );
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
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
}
