import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:remotecontrol/components/cursor_preview.dart';
import 'package:remotecontrol/components/split_container.dart';
import 'package:remotecontrol_lib/logger.dart';

import '../components/info_label.dart';
import '../components/log_box.dart';
import '../components/server_status.dart';
import '../components/text_button_input.dart';
import '../controllers/input_controller.dart';
import '../services/input_config.dart';
import '../services/win32_input_service.dart';

const _defaultPort = 9035;

class ServerPage extends StatefulWidget {
  const ServerPage({Key? key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  InputConfig config = Get.find<InputConfig>();

  final TextEditingController _portController =
      TextEditingController(text: "$_defaultPort");
  late Logger _logger;

  // gRPC server
  late InputServerController _server;

  get isServerSarted => _serverSatus == ServerStatus.online;
  String get serverIp => "127.0.0.1:${_portController.text}";
  ServerStatus _serverSatus = ServerStatus.offline;

  _ServerPageState() {
    _logger = Logger.instance();
    _server = InputServerController(_defaultPort, _logger);
    _server.setDebugEventHandler(inputEventHandler);

    config.updateNotifier.stream.listen((event) {
      setState(() {});
    });
  }

  void _stopServer() {
    if (_serverSatus == ServerStatus.online) {
      _server.stop().then((_) {
        setState(() {
          _serverSatus = ServerStatus.offline;
        });
      });
    }
  }

  void _startServer(int port) {
    if (_serverSatus == ServerStatus.offline) {
      _server.port = port;
      _server.listen();
      setState(() {
        _serverSatus = ServerStatus.online;
      });
    }
  }

  void inputEventHandler(InputReceivedEvent event, InputReceivedData data) {
    switch (data.runtimeType) {
      case MouseInputReceivedData:
        var d = data as MouseInputReceivedData;
        logger.log("Mouse moved: ${d.ajustedDeltaX}} ${d.ajustedDeltaY}");
        break;
      case MouseKeyInputReceivedData:
        var d = data as MouseKeyInputReceivedData;
        logger.log("Mouse key pressed: ${d.key} ${d.state ?? ''}");
        break;
      case KeyInputReceivedData:
        var d = data as KeyInputReceivedData;
        logger.log("Key pressed: ${d.virtualKeyCode} ${d.state ?? ''}");
        break;
      default:
        logger.log("Unknown InputReceivedData: ${data.runtimeType}");
    }
  }

  Widget buildHeader(double padding) {
    return Padding(
      padding: EdgeInsets.only(right: padding),
      child: Row(
        children: [
          Expanded(
            child: PageHeader(
              title: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 50),
                  child: const Text('Remote Input Server')),
            ),
          ),
          ServerStatusText(_serverSatus)
        ],
      ),
    );
  }

  Widget buildBottomBar(double padding) {
    return Row(
      children: [
        InfoBar(
          title: const Text('Config:'),
          content: Text(
            'Speed: ${config.cursorSpeed.toStringAsFixed(2)} '
            'Acceleration: ${config.cursorAcceleration.toStringAsFixed(2)}',
          ),
          style: InfoBarThemeData(
            padding: EdgeInsets.fromLTRB(padding, 0, 0, 0),
            decoration: (_) => const BoxDecoration(
              border: null,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDebugModeToggle() {
    return InfoLabel2(
      label: "Toggle Debug Mode",
      crossAxisAlignment: CrossAxisAlignment.end,
      child: Obx(() => ToggleSwitch(
          checked: config.isDebug,
          onChanged: (value) {
            config.isDebug = value;
            logger.log("Debug mode: ${config.isDebug}");
          })),
    );
  }

  Widget buildPortTextInput() {
    return TextButtonInput(
      header: 'Port',
      placeholder: _defaultPort.toString(),
      onPressed: () {
        if (!isServerSarted) {
          var port = int.tryParse(_portController.text);
          if (port != null) {
            _startServer(port);
          }
        } else {
          _stopServer();
        }
      },
      buttonText: isServerSarted ? 'Stop Server' : 'Start Server',
      autovalidateMode: AutovalidateMode.always,
      keyboardType: TextInputType.number,
      controller: _portController,
      textInputEnabled: !isServerSarted,
      validator: (text) {
        if (text == null || text.isEmpty) return 'Provide a port';
        if (int.tryParse(text) == null) return 'Port not valid';
        return null;
      },
      icon: const Icon(FluentIcons.plug),
      buttonIcon: isServerSarted
          ? const Icon(FluentIcons.stop_solid)
          : const Icon(FluentIcons.play_solid),
    );
  }

  Widget buildServerIpClippable() {
    return Row(
      children: [
        Text(
          "Server Ip: $serverIp",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(FluentIcons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: serverIp))
                .then((_) => _logger.trace("Copied server ip to clipboard"));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final padding = PageHeader.horizontalPadding(context);

    return ScaffoldPage(
        header: buildHeader(padding),
        bottomBar: buildBottomBar(padding),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildPortTextInput(),
                  buildDebugModeToggle(),
                ],
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text("Log"), buildServerIpClippable()],
                    ),
                    const Gap(5),
                    const SplitContainer(
                      direction: Direction.vertical,
                      expandRight: false,
                      left: LogBox(),
                      right: CursorPreview(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
