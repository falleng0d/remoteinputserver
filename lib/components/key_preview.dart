import 'package:fluent_ui/fluent_ui.dart';
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

class KeyHistoryPreview extends StatefulWidget {
  final InputServerController server;

  const KeyHistoryPreview({Key? key, required this.server}) : super(key: key);

  @override
  _KeyHistoryPreviewState createState() => _KeyHistoryPreviewState();
}

class _KeyHistoryPreviewState extends State<KeyHistoryPreview> {
  List<_KbdKey> keys = [];

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
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.server.clearDebugEventHandler(inputEventHandler);
  }

  Widget buildKey(_KbdKey key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(maxWidth: 40),
      decoration: BoxDecoration(
        color: () {
          switch (key._state) {
            case KeyActionType.DOWN:
              return Colors.red;
            case KeyActionType.UP:
              return Colors.green;
            default:
              return Colors.blue;
          }
        }(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          key.toString(),
          style: const TextStyle(color: Colors.white),
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
                  itemBuilder: (context, index) => buildKey(keys[index]),
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
