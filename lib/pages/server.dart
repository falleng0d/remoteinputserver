import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';

import '../components/log_box.dart';
import '../components/server_status.dart';
import '../logger.dart';
import '../server.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({Key? key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  final TextEditingController _portController = TextEditingController(text: "9035");
  ServerStatus _serverSatus = ServerStatus.offline;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final padding = PageHeader.horizontalPadding(context);

    return ScaffoldPage(
        header: PageHeader(
          title: const Text('Remote Input Server'),
          commandBar: SizedBox(
            width: 240.0,
            child: ServerStatusText(_serverSatus),
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
    if (_serverSatus == ServerStatus.offline) {
      startRemoteInputServer(port, Logger.instance());
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
