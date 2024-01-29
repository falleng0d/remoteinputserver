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

  const KeyHistoryPreview({super.key, required this.server});

  @override
  _KeyHistoryPreviewState createState() => _KeyHistoryPreviewState();
}

class _KeyHistoryPreviewState extends State<KeyHistoryPreview> {
  final List<Object> _keys = [];
  final List<_KbdKey> _modifiers = [];
  final KeyboardInputService _kbInputService = Get.find();

  @override
  initState() {
    super.initState();
    widget.server.setDebugEventHandler(inputEventHandler);
  }

  void inputEventHandler(InputReceivedEvent event, InputReceivedData data) {
    switch (data.runtimeType) {
      case KeyboardKeyReceivedData _:
        var d = data as KeyboardKeyReceivedData;
        setState(() {
          // add to front of list
          _keys.insert(0, _KbdKey(d.virtualKeyCode, state: d.state));
          if (_keys.length > 10) {
            _keys.removeLast();
          }
        });
        updateModifiers();
        break;
      case MouseButtonReceivedData _:
        var d = data as MouseButtonReceivedData;
        setState(() {
          // add to front of list
          _keys.insert(0, _MbButton(d.key, state: d.state));
          if (_keys.length > 10) {
            _keys.removeLast();
          }
        });
    }
  }

  void updateModifiers() {
    // schedule for 10ms later to allow for keypress to finish
    Future.delayed(const Duration(milliseconds: 10), () {
      final pressedModifiers = _kbInputService.modifierStates.values
          .where((e) => e.state == KeyState.DOWN)
          .map((e) => _KbdKey(e.vk))
          .toList();

      setState(() {
        _modifiers.clear();
        _modifiers.addAll(pressedModifiers);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.server.clearDebugEventHandler(inputEventHandler);
  }

  Widget buildKey(BuildContext context, Object key,
      {double size = 35.0, double fontSm = 8, double fontLg = 14}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      constraints: BoxConstraints(maxWidth: size),
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
            fontSize: key.toString().length >= 3 ? fontSm : fontLg,
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
                constraints: const BoxConstraints(maxHeight: 30),
                margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                child: ListView.builder(
                  itemCount: _modifiers.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => buildKey(
                    context,
                    _modifiers[index],
                    size: 30,
                    fontLg: 10,
                    fontSm: 7,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 35),
                margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                child: ListView.builder(
                  itemCount: _keys.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => buildKey(context, _keys[index]),
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
