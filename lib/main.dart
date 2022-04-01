// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:remotecontrol/model.dart';
import 'package:remotecontrol/server.dart';
import 'package:system_theme/system_theme.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

import 'logger.dart';
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
      [TargetPlatform.windows, TargetPlatform.android]
          .contains(defaultTargetPlatform)) {
    SystemTheme.accentInstance;
  }

  setPathUrlStrategy();

  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle('hidden',
          windowButtonVisibility: false);
      await windowManager.setSize(const Size(755, 545));
      await windowManager.setMinimumSize(const Size(755, 545));
      await windowManager.center();
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
          initialRoute: '/',
          routes: {'/': (_) => const MyHomePage(title: appTitle)},
          color: appTheme.color,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          theme: ThemeData(
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

  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  final settingsController = ScrollController();

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();

    logger.subscribe(Level.trace, (_, message) => print(message));

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
                  children: const [Spacer()],
                ),
              ),
      ),
      pane: NavigationPane(
        selected: index,
        onChanged: (i) => setState(() => index = i),
        size: const NavigationPaneSize(
          openMinWidth: 250,
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
        indicatorBuilder: () {
          switch (appTheme.indicator) {
            case NavigationIndicators.end:
              return NavigationIndicator.end;
            case NavigationIndicators.sticky:
            default:
              return NavigationIndicator.sticky;
          }
        }(),
        items: [
          // It doesn't look good when resizing from compact to open
          // PaneItemHeader(header: Text('User Interaction')),
          PaneItem(
            icon: const Icon(FluentIcons.analytics_view),
            title: const Text('Server'),
          ),
        ],
        autoSuggestBox: AutoSuggestBox(
          controller: TextEditingController(),
          items: const ['Server'],
        ),
        autoSuggestBoxReplacement: const Icon(FluentIcons.search),
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
          ),
        ],
      ),
      content: NavigationBody(index: index, children: const [
        MainPage(),
        //Settings(controller: settingsController),
      ]),
    );
  }

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      showDialog(
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

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _portController = TextEditingController(text: "9035");

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final padding = PageHeader.horizontalPadding(context);

    return ScaffoldPage(
        header: const PageHeader(
          title: Text('Remote Input Server'),
          commandBar: SizedBox(
            width: 240.0,
            child: ServerStatusText(ServerStatus.offline),
          ),
        ),
        bottomBar: const InfoBar(
          title: Text('Tip:'),
          content: Text(
            'You can click on any icon to execute the action.',
          ),
        ),
        content: Container(
          constraints: const BoxConstraints.expand(),
          padding: EdgeInsets.only(
            top: kPageDefaultVerticalPadding,
            right: padding,
            left: padding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  TextButtonInput(
                    header: 'Port',
                    placeholder: '9035',
                    onPressed: () {
                      var port = int.tryParse(_portController.text);
                      if (port != null) {
                        _startServer(port);
                      }
                    },
                    buttonText: 'Start Server',
                    autovalidateMode: AutovalidateMode.always,
                    keyboardType: TextInputType.number,
                    controller: _portController,
                    validator: (text) {
                      if (text == null || text.isEmpty) return 'Provide a port';
                      if (int.tryParse(text) == null) return 'Port not valid';
                      return null;
                    },
                    icon: const Icon(FluentIcons.plug),
                  ),
                ],
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Log"),
                        Text(
                          "Server Ip: 127.0.0.1:5050",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Gap(5),
                    const Expanded(child: LogBox()),
                  ],
                ),
              ),
            ],
          ),
        )

        /*GridView.extent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        padding: EdgeInsets.only(
          top: kPageDefaultVerticalPadding,
          right: padding,
          left: padding,
        ),
        children: [
          Button(
              child: const Text('Mouse Left Click'),
              onPressed: () async {
                Future.delayed(const Duration(seconds: 1),
                    () => mouseClick(MouseKeys.left));
              })
        ],
      ),*/
        );
  }

  void _startServer(int port) {
    startRemoteInputServer(port, Logger.instance());
  }
}

class LogBox extends StatefulWidget {
  const LogBox({Key? key}) : super(key: key);

  @override
  State<LogBox> createState() => _LogBoxState();
}

class _LogBoxState extends State<LogBox> {
  final _logController = TextEditingController();
  late final ScrollController _scrollController;
  List<void Function()> onDispose = [];
  bool isScrollToEnd = true;

  void log(String message) {
    setState(() {
      _logController.text = _logController.text + message + '\n';

      if (isScrollToEnd && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 10), (){
          _scrollToEnd();
        });
      }
    });
  }

  Future<void> _scrollToEnd() {
    var maxScroll = _scrollController.position.maxScrollExtent;
    return _scrollController.animateTo(maxScroll,
          duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
  }

  _LogBoxState() {
    _scrollController = ScrollController();
  }

  @override
  void initState() {
    super.initState();

    callback(_, message) => log(message);

    logger.subscribe(Level.trace, callback);

    onDispose.add(() {
      logger.unsubscribe(Level.trace, callback);
    });
  }

  @override
  void dispose() {
    _logController.dispose();
    for (var callback in onDispose) {
      callback();
    }
    onDispose.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: const Alignment(0.95, 0),
      fit: StackFit.passthrough,
      children: [
        TextBox(
          expands: true,
          maxLines: null,
          minLines: null,
          scrollController: _scrollController,
          controller: _logController,
          suffixMode: OverlayVisibilityMode.always,
          placeholder: 'Events will display here',
          readOnly: true,
        ),
        _logController.text.isEmpty ? Container() : buildClearButton(),
      ],
    );
  }

  Padding buildClearButton() {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(FluentIcons.chrome_close),
            onPressed: () => setState(() => _logController.clear()),
          ),
          IconButton(
            icon: const Icon(FluentIcons.double_chevron_down),
            key: const Key('scroll-to-end'),
            onPressed: () => setState(() {
              isScrollToEnd = !isScrollToEnd;
              if (isScrollToEnd) {
                _scrollToEnd();
              }
            }),
            style: ButtonStyle(
              backgroundColor: ButtonState.resolveWith((states) {
                return states.isDisabled
                    ? ButtonThemeData.buttonColor(theme.brightness, states)
                    : uncheckedInputColor(theme, states);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color uncheckedInputColor(ThemeData style, Set<ButtonStates> states) {
    if (style.brightness == Brightness.light) {
      if (isScrollToEnd) return const Color(0xFF221D08).withOpacity(0.155);
      if (states.isDisabled) return style.disabledColor;
      if (states.isPressing) return const Color(0xFF221D08).withOpacity(0.155);
      if (states.isHovering) return const Color(0xFF221D08).withOpacity(0.055);
      return Colors.transparent;
    } else {
      if (isScrollToEnd) return const Color(0xFFFFF3E8).withOpacity(0.080);
      if (states.isDisabled) return style.disabledColor;
      if (states.isPressing) return const Color(0xFFFFF3E8).withOpacity(0.080);
      if (states.isHovering) return const Color(0xFFFFF3E8).withOpacity(0.12);
      return Colors.transparent;
    }
  }
}

class TextButtonInput extends StatelessWidget {
  final void Function() onPressed;
  final String header;
  final String placeholder;
  final String? initialValue;
  final String buttonText;
  final AutovalidateMode? autovalidateMode;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Icon? icon;
  final TextEditingController? controller;

  const TextButtonInput({
    Key? key,
    required this.onPressed,
    required this.header,
    required this.placeholder,
    this.initialValue,
    required this.buttonText,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.icon,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          child: Expanded(
            child: TextFormBox(
              header: header,
              placeholder: placeholder,
              controller: controller,
              autovalidateMode: AutovalidateMode.always,
              keyboardType: keyboardType,
              validator: validator,
              textInputAction: TextInputAction.next,
              initialValue: initialValue,
              prefix: icon != null
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: icon,
                    )
                  : null,
            ),
          ),
        ),
        const Gap(8),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SizedBox(
            width: 120,
            height: 31,
            child: FilledButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ),
        ),
      ],
    );
  }
}

enum ServerStatus { online, offline }

class ServerStatusText extends StatelessWidget {
  final ServerStatus status;

  const ServerStatusText(
    this.status, {
    Key? key,
  }) : super(key: key);

  get statusColor {
    switch (status) {
      case ServerStatus.online:
        return Colors.green;
      case ServerStatus.offline:
        return Colors.red;
    }
  }

  get statusText {
    switch (status) {
      case ServerStatus.online:
        return "Online";
      case ServerStatus.offline:
        return "Offline";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Status: ",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 7),
          width: 17.0,
          height: 17.0,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
