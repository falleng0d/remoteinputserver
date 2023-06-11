import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:remotecontrol/components/split_container.dart';
import 'package:remotecontrol/input.dart';
import 'package:remotecontrol_lib/logger.dart';

import '../components/info_label.dart';
import '../components/log_box.dart';
import '../components/server_status.dart';
import '../components/text_button_input.dart';
import '../server_pb.dart';

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

    config.updateNotifier.stream.listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final padding = PageHeader.horizontalPadding(context);

    return ScaffoldPage(
        header: Padding(
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
        ),
        bottomBar: Row(
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButtonInput(
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
                  ),
                  InfoLabel2(
                    label: "Toggle Debug Mode",
                    crossAxisAlignment: CrossAxisAlignment.end,
                    child: Obx(() => ToggleSwitch(
                        checked: config.isDebug,
                        onChanged: (value) {
                          config.isDebug = value;
                          logger.log("Debug mode: ${config.isDebug}");
                        })),
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
                      children: [
                        const Text("Log"),
                        Row(
                          children: [
                            Text(
                              "Server Ip: $serverIp",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(FluentIcons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: serverIp))
                                    .then((_) => _logger.trace(
                                        "Copied server ip to clipboard"));
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const Gap(5),
                    SplitContainer(
                      direction: Direction.vertical,
                      left: const LogBox(),
                      right: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.theme.primaryColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
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
}
