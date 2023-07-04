import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:remotecontrol_lib/virtualkeys.dart';

import '../controllers/input_controller.dart';
import '../services/win32_input_service.dart';

class _KbdKey {
  final int virtualKeyCode;
  final KeyActionType? _state;

  get state => _state != null ? '_$_state' : null;

  get label => vkToKey(virtualKeyCode);

  _KbdKey(this.virtualKeyCode, {KeyActionType? state}) : _state = state;

  @override
  String toString() => label;
}

class _MbButton {
  final MouseButton button;
  final ButtonActionType? _state;

  get state => _state != null ? '_$_state' : null;

  get label => "MB${button.toString().split('.').last.substring(0, 1)}";

  _MbButton(this.button, {ButtonActionType? state}) : _state = state;

  @override
  String toString() => label;
}

class KeyHistoryPreview extends StatefulWidget {
  final InputServerController server;

  const KeyHistoryPreview({Key? key, required this.server}) : super(key: key);

  @override
  _KeyHistoryPreviewState createState() => _KeyHistoryPreviewState();
}

class _KeyHistoryPreviewState extends State<KeyHistoryPreview> {
  List<Object> keys = [];

  @override
  initState() {
    super.initState();
    widget.server.setDebugEventHandler(inputEventHandler);
  }

  void inputEventHandler(InputReceivedEvent event, InputReceivedData data) {
    switch (data.runtimeType) {
      case KeyboardKeyReceivedData:
        var d = data as KeyboardKeyReceivedData;
        setState(() {
          // add to front of list
          keys.insert(0, _KbdKey(d.virtualKeyCode, state: d.state));
          if (keys.length > 10) {
            keys.removeLast();
          }
        });
        break;
      case MouseButtonReceivedData:
        var d = data as MouseButtonReceivedData;
        setState(() {
          // add to front of list
          keys.insert(0, _MbButton(d.key, state: d.state));
          if (keys.length > 10) {
            keys.removeLast();
          }
        });
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.server.clearDebugEventHandler(inputEventHandler);
  }

  Widget buildKey(BuildContext context, Object key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(maxWidth: 40),
      decoration: BoxDecoration(
        color: () {
          if (key is _KbdKey) {
            switch (key._state) {
              case KeyActionType.DOWN:
                return Colors.red;
              case KeyActionType.UP:
                return Colors.green;
              default:
                return Colors.blue;
            }
          } else if (key is _MbButton) {
            switch (key._state) {
              case ButtonActionType.DOWN:
                return Colors.red;
              case ButtonActionType.UP:
                return Colors.green;
              default:
                return Colors.blue;
            }
          }
        }(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          key.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize:
                key.toString().length >= 3 ? 10 : context.textTheme.bodyMedium?.fontSize,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Flex(
            direction: Axis.vertical,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 40),
                margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: ListView.builder(
                  itemCount: keys.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => buildKey(context, keys[index]),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}
