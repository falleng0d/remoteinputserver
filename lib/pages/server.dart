import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:remotecontrol_lib/logger.dart';

import '../components/log_box.dart';
import '../components/server_status.dart';
import '../server_pb.dart';

const _defaultPort = 9035;

class ServerPage extends StatefulWidget {
  const ServerPage({Key? key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
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
              title: const Text('Tip:'),
              content: const Text(
                'You can click on any icon to execute the action.',
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
  final Icon? buttonIcon;
  final TextEditingController? controller;
  final bool enabled;
  final bool textInputEnabled;

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
    this.buttonIcon,
    this.controller,
    this.enabled = true,
    this.textInputEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          child: InfoLabel(
            label: header,
            child: TextFormBox(
              placeholder: placeholder,
              controller: controller,
              autovalidateMode: AutovalidateMode.always,
              keyboardType: keyboardType,
              validator: validator,
              textInputAction: TextInputAction.next,
              initialValue: initialValue,
              enabled: enabled && textInputEnabled,
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
          padding: const EdgeInsets.only(top: 27),
          child: SizedBox(
            width: 130,
            height: 32,
            child: FilledButton(
              onPressed: enabled ? onPressed : null,
              child: buttonIcon != null
                  ? Row(
                      children: [
                        buttonIcon!,
                        const Gap(5),
                        Text(buttonText),
                      ],
                    )
                  : Text(buttonText),
            ),
          ),
        ),
      ],
    );
  }
}
